import React, { useRef } from 'react';
import { motion, useMotionTemplate, useMotionValue, useSpring, useTransform } from 'framer-motion';
import { ServiceCardProps } from '../../types';

export const JellyCard: React.FC<ServiceCardProps> = ({ 
  title, 
  subtitle, 
  icon: Icon, 
  colorClass,
  delay = 0,
  onClick,
  className = "",
  children
}) => {
  // 3D Tilt Logic
  const ref = useRef<HTMLDivElement>(null);
  const x = useMotionValue(0);
  const y = useMotionValue(0);

  // Smooth out the mouse values
  const xSpring = useSpring(x, { stiffness: 300, damping: 20 });
  const ySpring = useSpring(y, { stiffness: 300, damping: 20 });

  const transform = useMotionTemplate`perspective(1000px) rotateX(${xSpring}deg) rotateY(${ySpring}deg)`;

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!ref.current) return;
    const rect = ref.current.getBoundingClientRect();
    const width = rect.width;
    const height = rect.height;
    
    // Calculate mouse position relative to center of card
    const mouseX = e.clientX - rect.left;
    const mouseY = e.clientY - rect.top;
    
    const rX = (mouseY / height - 0.5) * 10; // Rotate X between -5 and 5 deg
    const rY = (mouseX / width - 0.5) * -10; // Rotate Y between -5 and 5 deg

    x.set(rX);
    y.set(rY);
  };

  const handleMouseLeave = () => {
    x.set(0);
    y.set(0);
  };

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, scale: 0.9, y: 20 }}
      animate={{ opacity: 1, scale: 1, y: 0 }}
      transition={{ 
        type: "spring",
        stiffness: 260,
        damping: 20,
        delay: delay,
        mass: 1
      }}
      style={{ transform }}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.96 }}
      onClick={onClick}
      className={`
        relative overflow-hidden
        rounded-[32px] 
        ${colorClass}
        shadow-[0_8px_30px_rgb(0,0,0,0.04)]
        hover:shadow-[0_8px_30px_rgb(0,0,0,0.08)]
        cursor-pointer
        flex flex-col
        group
        transition-shadow duration-300
        border border-white/20
        ${className}
      `}
    >
        {/* Dynamic Glare Effect */}
        <motion.div 
            style={{ 
                background: useMotionTemplate`radial-gradient(
                    circle at ${useTransform(ySpring, [-5, 5], ["0%", "100%"])} ${useTransform(xSpring, [-5, 5], ["0%", "100%"])}, 
                    rgba(255,255,255,0.3) 0%, 
                    transparent 60%
                )`
            }}
            className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none z-20"
        />

        {/* Liquid Background Blobs - Refined */}
        <div className="absolute top-[-50%] right-[-50%] w-[120%] h-[120%] bg-gradient-to-br from-white/30 to-transparent rounded-full blur-3xl opacity-60 group-hover:scale-110 transition-transform duration-1000 ease-out" />
        
        {/* We use a conditional render here. If children exist and we passed specific classes, 
            we might not want standard padding. But for default usage, we keep standard structure.
            Since className is passed to the outer div, we check if title is empty to determine layout mode.
        */}
        <div className={`relative z-10 flex flex-col h-full ${title ? 'p-6' : ''}`}>
             {/* Only render header if title exists. If not, it's a custom layout card (like Events) */}
            {title && (
                <div className="flex justify-between items-start mb-auto">
                    {Icon && (
                        <div 
                            className="w-12 h-12 flex items-center justify-center bg-white/60 backdrop-blur-md rounded-2xl shadow-sm text-current border border-white/40"
                        >
                            <Icon size={24} strokeWidth={2.5} />
                        </div>
                    )}
                </div>
            )}

            {/* Content Area */}
            <div className={title ? "mt-4" : "w-full h-full"}>
                {title && <h3 className="text-[22px] font-bold mb-1 tracking-tight leading-none text-current opacity-90">{title}</h3>}
                {title && subtitle && <p className="text-sm font-semibold opacity-60 leading-tight">{subtitle}</p>}
                {children}
            </div>
        </div>
    </motion.div>
  );
};