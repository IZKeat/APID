
import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Store, Search, LayoutGrid, User, BookOpen, ListTodo, Users } from 'lucide-react';
import Sidebar, { MenuItem } from './components/Sidebar';
import ProductCard from './components/ProductCard';
import Cart from './components/Cart';
import Profile from './components/Profile';
import Login from './components/Login';
import Library from './components/Library';
import Access from './components/Access';
import Attendance from './components/Attendance';
import { Product, CartItem, Category, ViewType } from './types';
import { PRODUCTS, CATEGORIES, ANIMATION_SPRING } from './constants';

// Simple ID generator
const generateId = () => Math.random().toString(36).substr(2, 9);

const App = () => {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [currentUserEmail, setCurrentUserEmail] = useState('');
  const [currentView, setCurrentView] = useState<ViewType>('POS');
  const [activeCategory, setActiveCategory] = useState<Category>('All');
  const [cart, setCart] = useState<CartItem[]>([]);
  const [searchQuery, setSearchQuery] = useState('');

  // Define menus based on user role
  const getMenuItems = (email: string): MenuItem[] => {
    if (email.startsWith('sp002')) {
       return [
        { icon: BookOpen, label: 'Library', view: 'LIBRARY' },
        { icon: User, label: 'Profile', view: 'PROFILE' },
       ];
    }
    if (email.startsWith('sp006')) {
       return [
        { icon: ListTodo, label: 'Access', view: 'ACCESS' },
        { icon: User, label: 'Profile', view: 'PROFILE' },
       ];
    }
    if (email.startsWith('sp007')) {
       return [
        { icon: Users, label: 'Attendance', view: 'ATTENDANCE' },
        { icon: User, label: 'Profile', view: 'PROFILE' },
       ];
    }
    // Default POS user
    return [
      { icon: LayoutGrid, label: 'POS', view: 'POS' },
      { icon: User, label: 'Profile', view: 'PROFILE' },
    ];
  };

  const filteredProducts = PRODUCTS.filter(product => {
    const matchesCategory = activeCategory === 'All' || product.category === activeCategory;
    const matchesSearch = product.name.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  const addToCart = (product: Product) => {
    setCart(prev => {
      const existingItem = prev.find(item => item.id === product.id);
      if (existingItem) {
        return prev.map(item => 
          item.id === product.id 
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      }
      return [...prev, { ...product, quantity: 1, uuid: generateId() }];
    });
  };

  const updateQuantity = (uuid: string, delta: number) => {
    setCart(prev => prev.map(item => {
      if (item.uuid === uuid) {
        const newQuantity = Math.max(0, item.quantity + delta);
        return { ...item, quantity: newQuantity };
      }
      return item;
    }).filter(item => item.quantity > 0));
  };

  const removeItem = (uuid: string) => {
    setCart(prev => prev.filter(item => item.uuid !== uuid));
  };

  const handleLogin = (email: string) => {
    setCurrentUserEmail(email);
    setIsLoggedIn(true);
    
    // Route to appropriate view based on email
    if (email.startsWith('sp002')) {
      setCurrentView('LIBRARY');
    } else if (email.startsWith('sp006')) {
      setCurrentView('ACCESS');
    } else if (email.startsWith('sp007')) {
      setCurrentView('ATTENDANCE');
    } else {
      setCurrentView('POS');
    }
  };

  const handleLogout = () => {
    setIsLoggedIn(false);
    setCurrentView('POS'); // Reset view on logout
    setCart([]); // Clear cart on logout
    setCurrentUserEmail('');
  };

  const renderContent = () => {
    switch (currentView) {
      case 'POS':
        return (
          <motion.div
            key="POS"
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 20 }}
            transition={{ duration: 0.3 }}
            className="flex-1 flex flex-col h-full overflow-hidden"
          >
            {/* POS Header */}
            <header className="px-8 py-6 flex items-center justify-between shrink-0">
              <div className="flex items-center gap-4">
                <div className="p-3 bg-purple-100 rounded-2xl text-purple-700">
                  <Store size={28} />
                </div>
                <div>
                  <h1 className="text-2xl font-bold text-gray-900">Smokey Café</h1>
                  <p className="text-gray-400 text-sm font-medium">POS System • Morning Shift</p>
                </div>
              </div>

              <div className="relative">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
                <input 
                  type="text" 
                  placeholder="Search menu..." 
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-12 pr-4 py-3 bg-white rounded-2xl border-none shadow-sm w-64 focus:ring-2 focus:ring-purple-200 focus:outline-none transition-all"
                />
              </div>
            </header>

            {/* Categories */}
            <div className="px-8 pb-4 flex gap-3 overflow-x-auto no-scrollbar shrink-0">
              {CATEGORIES.map((cat) => (
                <motion.button
                  key={cat}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => setActiveCategory(cat as Category)}
                  className={`px-6 py-2.5 rounded-full font-medium text-sm transition-colors whitespace-nowrap ${
                    activeCategory === cat 
                      ? 'bg-gray-900 text-white shadow-lg shadow-gray-200' 
                      : 'bg-white text-gray-500 hover:bg-gray-100'
                  }`}
                >
                  {cat}
                </motion.button>
              ))}
            </div>

            {/* Product Grid */}
            <div className="flex-1 overflow-y-auto px-8 pb-8 pt-2 no-scrollbar">
              <motion.div 
                layout
                className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
              >
                {filteredProducts.map((product) => (
                  <ProductCard key={product.id} product={product} onAdd={addToCart} />
                ))}
              </motion.div>
              {filteredProducts.length === 0 && (
                <div className="h-64 flex items-center justify-center text-gray-400">
                  No products found.
                </div>
              )}
            </div>
          </motion.div>
        );
      
      case 'LIBRARY':
        return <Library key="LIBRARY" />;

      case 'ACCESS':
        return <Access key="ACCESS" />;

      case 'ATTENDANCE':
        return <Attendance key="ATTENDANCE" />;

      case 'PROFILE':
        return <Profile key="PROFILE" userEmail={currentUserEmail} />;

      default:
        return null;
    }
  };

  return (
    <div className="flex h-screen w-screen bg-[#f3f4f6] text-gray-800 font-sans overflow-hidden">
      <AnimatePresence mode="wait">
        {!isLoggedIn ? (
          <motion.div 
            key="login"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0, scale: 1.1, filter: "blur(10px)" }}
            transition={{ duration: 0.5 }}
            className="w-full h-full"
          >
            <Login onLogin={handleLogin} />
          </motion.div>
        ) : (
          <motion.div 
            key="dashboard"
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.5, type: "spring", stiffness: 100 }}
            className="flex h-full w-full"
          >
            {/* Left Sidebar */}
            <Sidebar 
              activeView={currentView} 
              onNavigate={setCurrentView} 
              onLogout={handleLogout} 
              menuItems={getMenuItems(currentUserEmail)}
            />

            {/* Main Content Area */}
            <main className="flex-1 flex flex-col h-full overflow-hidden relative z-10">
              
              {/* Animated View Switcher */}
              <AnimatePresence mode="wait">
                {renderContent()}
              </AnimatePresence>
            </main>

            {/* Right Sidebar (Cart) - Only visible in POS view */}
            <AnimatePresence>
              {currentView === 'POS' && (
                <motion.aside 
                  initial={{ x: 100, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  exit={{ x: 100, opacity: 0 }}
                  transition={ANIMATION_SPRING}
                  className="w-[400px] h-full p-4 pl-0 shrink-0 hidden md:block"
                >
                   <Cart 
                      items={cart} 
                      onUpdateQuantity={updateQuantity} 
                      onRemove={removeItem}
                      onClear={() => setCart([])}
                   />
                </motion.aside>
              )}
            </AnimatePresence>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default App;
