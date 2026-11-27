// #############################################
// #    FIBONACCI DUNGEON — GRAPHICAL GUI      #
// #       eframe / egui desktop app           #
// #############################################

use eframe::egui;
use egui::{CentralPanel, Panel};
use fibonacci_dungeon as fd;

// Which screen we are looking at
#[derive(PartialEq)]
enum Screen {
    Map,
    Floors,
    Boss,
}

// The main app holding our state
struct DungeonApp {
    n: i64,
    stats: Option<fd::DungeonStats>,
    map_before: Vec<String>,
    map_after: Vec<String>,
    show_curse: bool,
    screen: Screen,
}

impl Default for DungeonApp {
    fn default() -> Self {
        let mut app = DungeonApp {
            n: 6,
            stats: None,
            map_before: Vec::new(),
            map_after: Vec::new(),
            show_curse: false,
            screen: Screen::Map,
        };
        app.rebuild(6);
        app
    }
}

impl DungeonApp {
    // Recompute everything for a chosen n
    fn rebuild(&mut self, n: i64) {
        let n = n.clamp(0, 20); // keep it fast for the GUI
        self.n = n;
        self.stats = Some(fd::compute_stats(n));

        // Map with the curse on: highlights duplicates
        let (before, _) = fd::build_map_lines(n, true);
        self.map_before = before;

        // Map with the curse off (the ward has been cast)
        let (after, _) = fd::build_map_lines(n, false);
        self.map_after = after;
    }
}

impl eframe::App for DungeonApp {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        // Top bar with navigation and depth selector
        Panel::top(egui::Id::new("top")).show(ui, |ui| {
            ui.horizontal(|ui| {
                ui.heading("🏰 Fibonacci Dungeon");
                ui.separator();

                if ui.button("🗺️ Map").clicked() {
                    self.screen = Screen::Map;
                }
                if ui.button("📊 Floors").clicked() {
                    self.screen = Screen::Floors;
                }
                if ui.button("📜 Boss").clicked() {
                    self.screen = Screen::Boss;
                }

                ui.separator();
                ui.label("Depth n:");
                if ui.add(egui::DragValue::new(&mut self.n).range(0..=20)).changed() {
                    self.rebuild(self.n);
                }
            });
        });

        // The center of the window for the active screen
        match self.screen {
            Screen::Map => self.draw_map(ui),
            Screen::Floors => self.draw_floors(ui),
            Screen::Boss => self.draw_boss(ui),
        }
    }
}

impl DungeonApp {
    // The interactive tree map
    fn draw_map(&mut self, ui: &mut egui::Ui) {
        let stats = self.stats.clone().unwrap_or(fd::DungeonStats {
            n: 0,
            fib: 0,
            rooms_unwarded: 0,
            leaves: 0,
            height: 0,
            rooms_warded: 0,
        });

        CentralPanel::default().show(ui, |ui| {
            ui.heading(format!("🗺️ Dungeon Map — depth n = {}", self.n));
            ui.label(format!(
                "Treasure at the entrance = fib({}) = {}",
                self.n, stats.fib
            ));
            ui.separator();

            ui.horizontal(|ui| {
                ui.label("Show duplicates (the Curse before the Memory Ward):");
                ui.toggle_value(&mut self.show_curse, "Curse visible");
            });
            if self.show_curse {
                ui.label("⚠️ Rooms marked with ⚠️ are built more than once before the ward.");
            } else {
                ui.label("✅ The Memory Ward is active: each room is built only once.");
            }
            ui.separator();

            if let Some(s) = self.stats {
                ui.label(format!(
                    "Rooms: {} before ward → {} after ward ({}x fewer)",
                    s.rooms_unwarded,
                    s.rooms_warded,
                    if s.rooms_warded > 0 { s.rooms_unwarded / s.rooms_warded } else { 0 }
                ));
            }
            ui.separator();

            egui::ScrollArea::vertical()
                .auto_shrink([false, false])
                .show(ui, |ui| {
                    let lines = if self.show_curse { &self.map_before } else { &self.map_after };
                    for line in lines {
                        ui.monospace(line);
                    }
                });
        });
    }

    // Stats / analysis screen
    fn draw_floors(&mut self, ui: &mut egui::Ui) {
        let stats = self.stats.clone().unwrap_or(fd::DungeonStats {
            n: 0,
            fib: 0,
            rooms_unwarded: 0,
            leaves: 0,
            height: 0,
            rooms_warded: 0,
        });

        CentralPanel::default().show(ui, |ui| {
            ui.heading("📊 Floor Analysis");
            ui.add_space(4.0);

            ui.label(format!(
                "▶ Floor 1 & 2: fib({}) = {}  — built the recursion tree, walked it post-order to collect treasure.",
                stats.n, stats.fib
            ));
            ui.separator();

            ui.label("▶ Floor 3: Cartographer's Survey");
            egui::Grid::new("survey").num_columns(2).show(ui, |ui| {
                ui.label("🏰 Total rooms (un-warded):");
                ui.monospace(format!("{}", stats.rooms_unwarded));
                ui.end_row();

                ui.label("💀 Sealed chambers (leaves):");
                ui.monospace(format!("{}", stats.leaves));
                ui.end_row();

                ui.label("📏 Dungeon height:");
                ui.monospace(format!("{}", stats.height));
                ui.end_row();

                ui.label("🏰 Rooms (warded DAG):");
                ui.monospace(format!("{}", stats.rooms_warded));
                ui.end_row();
            });
            ui.separator();

            ui.label("▶ Floor 4: The Memory Ward — the curse broken");
            ui.label(format!(
                "   {} rooms BEFORE the ward vs {} AFTER ({}x fewer)",
                stats.rooms_unwarded,
                stats.rooms_warded,
                if stats.rooms_warded > 0 {
                    stats.rooms_unwarded / stats.rooms_warded
                } else {
                    0
                }
            ));
            ui.label("   The warded dungeon is linear (O(n)); the un-warded is exponential (O(φⁿ)).");
            ui.label("   Try raising the depth n to see the gap widen dramatically.");
        });
    }

    // Boss fight essay
    fn draw_boss(&self, ui: &mut egui::Ui) {
        CentralPanel::default().show(ui, |ui| {
            ui.heading("📜 Boss Fight — Written Trial");
            ui.add_space(4.0);
            ui.separator();

            scroll_text(ui,
                "Q1: Why does the un-warded dungeon explode exponentially, while the warded one grows linearly?",
                "In the un-warded tree every corridor builds its rooms from scratch, so each room fib(k) is rebuilt over and over. The number of rooms follows the Fibonacci pattern and grows like φⁿ (golden ratio to the n) — exponential. The warded dungeon stores each room once in a HashMap and reuses it, so we only build n+1 rooms — linear (O(n)).");
            scroll_text(ui,
                "Q2: How is the Memory Ward secretly top-down Dynamic Programming wearing a costume?",
                "Top-down DP solves the problem recursively but caches each sub-problem's answer so it is never solved twice. The Memory Ward does exactly that — it caches each room in a memo table and reuses it. So the ward IS memoization, which is the heart of top-down DP.");
            scroll_text(ui,
                "Q3: If you explored the un-warded dungeon level-by-level (breadth-first), what would each level represent?",
                "Each level represents a fixed value of n. Level k holds every room with value k. In the un-warded tree a level has many duplicate rooms with the same value; in the warded DAG each level has exactly one room. Breadth-first traversal exposes the exponential branching of the curse, while the warded version shows the clean linear structure.");
            scroll_text(ui,
                "Complexity",
                "Un-warded (cursed): O(φⁿ) rooms, exponential time. Warded (memoized): O(n) rooms, O(n) time, O(n) space.");
        });
    }
}

// Small helper to render a scroll block
fn scroll_text(ui: &mut egui::Ui, title: &str, body: &str) {
    ui.add_space(4.0);
    ui.label(egui::RichText::new(format!("▶ {}", title)).strong());
    ui.label(body);
    ui.add_space(6.0);
}

// Entry point for the GUI app
fn main() -> eframe::Result<()> {
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_inner_size([760.0, 640.0])
            .with_title("Fibonacci Dungeon"),
        ..Default::default()
    };
    eframe::run_native(
        "Fibonacci Dungeon",
        options,
        Box::new(|_cc| Ok(Box::new(DungeonApp::default()))),
    )
}
