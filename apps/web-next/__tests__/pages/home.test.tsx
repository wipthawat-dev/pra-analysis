import { render, screen } from '@testing-library/react'
import Home from '@/app/page'

describe('Home Page', () => {
  it('renders the page title', () => {
    render(<Home />)
    const heading = screen.getByText(/Pra Analysis/i)
    expect(heading).toBeInTheDocument()
  })

  it('renders all 6 feature cards', () => {
    render(<Home />)
    
    expect(screen.getByText(/Analyze Image/i)).toBeInTheDocument()
    expect(screen.getByText(/Datasets/i)).toBeInTheDocument()
    expect(screen.getByText(/Labeling/i)).toBeInTheDocument()
    expect(screen.getByText(/Training/i)).toBeInTheDocument()
    expect(screen.getByText(/Models/i)).toBeInTheDocument()
    expect(screen.getByText(/Feedback/i)).toBeInTheDocument()
  })

  it('renders feature card descriptions', () => {
    render(<Home />)
    
    expect(screen.getByText(/Upload and analyze amulet images/i)).toBeInTheDocument()
    expect(screen.getByText(/Manage datasets/i)).toBeInTheDocument()
    expect(screen.getByText(/Label images for training/i)).toBeInTheDocument()
  })

  it('renders quick start section', () => {
    render(<Home />)
    
    expect(screen.getByText(/Quick Start/i)).toBeInTheDocument()
    expect(screen.getByText(/Upload Images/i)).toBeInTheDocument()
    expect(screen.getByText(/Label Data/i)).toBeInTheDocument()
    expect(screen.getByText(/Train Models/i)).toBeInTheDocument()
    expect(screen.getByText(/Deploy & Analyze/i)).toBeInTheDocument()
  })

  it('has correct navigation links', () => {
    render(<Home />)
    
    const analyzeLink = screen.getByRole('link', { name: /Analyze Image/i })
    expect(analyzeLink).toHaveAttribute('href', '/analyze')
    
    const datasetsLink = screen.getByRole('link', { name: /Datasets/i })
    expect(datasetsLink).toHaveAttribute('href', '/admin/datasets')
  })

  it('renders with proper accessibility', () => {
    const { container } = render(<Home />)
    
    // Check for main landmark
    const main = container.querySelector('main')
    expect(main).toBeInTheDocument()
  })
})

