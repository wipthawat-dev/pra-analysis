import { render, screen } from '@testing-library/react'
import Navigation from '@/components/navigation'

// Mock next/link
jest.mock('next/link', () => {
  return ({ children, href }: any) => {
    return <a href={href}>{children}</a>
  }
})

describe('Navigation Component', () => {
  it('renders navigation links', () => {
    render(<Navigation />)
    
    // This test depends on your actual Navigation component implementation
    // Adjust based on what links you have
    const links = screen.getAllByRole('link')
    expect(links.length).toBeGreaterThan(0)
  })

  it('renders without crashing', () => {
    const { container } = render(<Navigation />)
    expect(container).toBeInTheDocument()
  })
})

