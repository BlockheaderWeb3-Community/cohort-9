import React from 'react'

type ButtonProps = {
  label: string;
  onClick?: () => void;
  type?: 'button' | 'submit';
  variant?: 'primary' | 'danger';
  disabled?: boolean;
}

const Button = ({ label, onClick, type = 'button', variant = 'primary', disabled = false }: ButtonProps) => {
  const base = 'w-52 py-2 px-4 rounded text-white font-semibold transition-opacity';
  const variants = {
    primary: 'bg-blue-500 hover:bg-blue-600',
    danger: 'bg-red-500 hover:bg-red-600',
  };

  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`${base} ${variants[variant]} ${disabled ? 'opacity-50 cursor-not-allowed' : ''}`}
    >
      {label}
    </button>
  )
}

export default Button