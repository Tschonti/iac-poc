import { useEffect, useState } from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './App.css'

type Fact = {
  event2: string
}

function App() {
  const [count, setCount] = useState(0)
  const [fact, setFact] = useState('')

  useEffect(() => {
    fetchFact()
  }, [])

  const fetchFact = async () => {
    const month: string = `${new Date().getMonth() + 1}`
    const day: string = `${new Date().getDate() + 1}`
    const res = await fetch(`https://wikimedia-tf.azure-api.net/selected/${month.padStart(2, '0')}/${day.padStart(2, '0')}`)
    const data: Fact = await res.json()
    setFact(data.event2)
  }


  return (
    <>
      <div>
        <a href="https://vitejs.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React</h1>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
        <p>
          Edit <code>src/App.tsx</code> and save to test HMR
        </p>
      </div>
      <p className="read-the-docs">
        On this day: {fact}
      </p>
    </>
  )
}

export default App
