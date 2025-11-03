import React, { useEffect, useState } from "react";
import axios from "axios";
// Temporarily disabled auth import
// import { fetchAuthSession } from "aws-amplify/auth";

export default function Tasks() {
  const [tasks, setTasks] = useState([]);
  const [title, setTitle] = useState("");

  const API_URL = "https://s0wt8rhr5j.execute-api.us-east-1.amazonaws.com/prod/tasks";

  const fetchTasks = async () => {
    try {
      // Temporarily disabled auth for development
      // const session = await fetchAuthSession();
      // const token = session.tokens?.idToken?.toString();

      const res = await axios.get(API_URL, {
        // headers: { Authorization: token },
      });
      setTasks(res.data);
    } catch (err) {
      console.error("Fetch error:", err);
      // For demo purposes, set some mock data
      setTasks([
        { taskId: '1', title: 'Sample Task 1', status: 'pending' },
        { taskId: '2', title: 'Sample Task 2', status: 'completed' }
      ]);
    }
  };

  const addTask = async (e) => {
    e.preventDefault();
    try {
      // Temporarily disabled auth for development
      // const session = await fetchAuthSession();
      // const token = session.tokens?.idToken?.toString();

      await axios.post(
        API_URL,
        { title },
        // { headers: { Authorization: token } }
      );

      setTitle("");
      fetchTasks();
    } catch (err) {
      console.error("Add task error:", err);
      // For demo purposes, add task locally
      setTasks(prev => [...prev, { 
        taskId: Date.now().toString(), 
        title, 
        status: 'pending' 
      }]);
      setTitle("");
    }
  };

  useEffect(() => {
    fetchTasks();
  }, []);

  return (
    <div className="min-h-screen bg-gray-100 flex flex-col items-center py-8">
      <h1 className="text-3xl font-bold mb-6">My Tasks</h1>

      <form onSubmit={addTask} className="flex gap-2 mb-6">
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Enter task..."
          className="border p-2 rounded w-64"
        />
        <button type="submit" className="bg-blue-500 text-white px-4 py-2 rounded">
          Add
        </button>
      </form>

      <ul className="w-80">
        {tasks.map((task) => (
          <li key={task.taskId} className="bg-white shadow p-3 mb-2 rounded flex justify-between items-center">
            <span>{task.title}</span>
            <span className="text-sm text-gray-500">{task.status}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}