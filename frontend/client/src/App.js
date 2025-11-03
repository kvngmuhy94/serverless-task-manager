import React from "react";
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
// Temporarily disabled Amplify configuration
// import { Amplify } from 'aws-amplify';
// import awsConfig from './aws-exports';
import Tasks from "./Tasks";
import Login from "./Login";
import Register from "./Register";

// Configure Amplify - disabled until User Pool is deployed
// Amplify.configure(awsConfig);  

function App() {
  return (
    <Router>
      <div>
        {/* Simple Navigation */}
        <nav className="bg-blue-600 p-4">
          <div className="flex space-x-4">
            <a href="/" className="text-white hover:text-blue-200">Tasks</a>
            <a href="/login" className="text-white hover:text-blue-200">Login</a>
            <a href="/register" className="text-white hover:text-blue-200">Register</a>
          </div>
        </nav>
        
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/" element={<Tasks />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;