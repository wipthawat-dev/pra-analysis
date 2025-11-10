import { apiRequest, datasetsApi, labelingApi, trainingApi, modelsApi, feedbackApi } from '@/lib/api'

describe('API Client', () => {
  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks()
    ;(global.fetch as jest.Mock).mockClear()
  })

  describe('apiRequest', () => {
    it('makes successful GET request', async () => {
      const mockData = { id: '123', name: 'Test' }
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => mockData,
      })

      const result = await apiRequest('/test')
      
      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:8000/test',
        expect.objectContaining({
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
          }),
        })
      )
      expect(result).toEqual(mockData)
    })

    it('throws error on failed request', async () => {
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: false,
        status: 404,
        json: async () => ({ detail: 'Not found' }),
      })

      await expect(apiRequest('/test')).rejects.toThrow('Not found')
    })

    it('handles network errors', async () => {
      ;(global.fetch as jest.Mock).mockRejectedValueOnce(new Error('Network error'))

      await expect(apiRequest('/test')).rejects.toThrow('Network error')
    })
  })

  describe('datasetsApi', () => {
    it('lists datasets', async () => {
      const mockDatasets = [{ id: '1', name: 'Dataset 1' }]
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => mockDatasets,
      })

      const result = await datasetsApi.list()
      
      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:8000/v1/admin/datasets',
        expect.any(Object)
      )
      expect(result).toEqual(mockDatasets)
    })

    it('creates dataset', async () => {
      const newDataset = { name: 'New Dataset', description: 'Test' }
      const mockResponse = { id: '123', ...newDataset }
      
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse,
      })

      const result = await datasetsApi.create(newDataset)
      
      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:8000/v1/admin/datasets',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify(newDataset),
        })
      )
      expect(result).toEqual(mockResponse)
    })

    it('gets dataset by id', async () => {
      const mockDataset = { id: '123', name: 'Test Dataset' }
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => mockDataset,
      })

      const result = await datasetsApi.get('123')
      
      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:8000/v1/admin/datasets/123',
        expect.any(Object)
      )
      expect(result).toEqual(mockDataset)
    })

    it('deletes dataset', async () => {
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => ({ message: 'Deleted' }),
      })

      await datasetsApi.delete('123')
      
      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:8000/v1/admin/datasets/123',
        expect.objectContaining({ method: 'DELETE' })
      )
    })
  })

  describe('labelingApi', () => {
    it('gets labeling queue', async () => {
      const mockQueue = [{ id: '1', minio_path: 'test.jpg', is_labeled: false }]
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => mockQueue,
      })

      const result = await labelingApi.getQueue()
      
      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:8000/v1/admin/labeling/queue',
        expect.any(Object)
      )
      expect(result).toEqual(mockQueue)
    })

    it('creates label', async () => {
      const labelData = { verdict: 'authentic', confidence: 95 }
      const mockResponse = { id: '123', ...labelData, image_id: '456' }
      
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse,
      })

      const result = await labelingApi.createLabel('456', labelData)
      
      expect(result).toEqual(mockResponse)
    })
  })

  describe('trainingApi', () => {
    it('lists training jobs', async () => {
      const mockJobs = [{ id: '1', status: 'pending' }]
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => mockJobs,
      })

      const result = await trainingApi.listJobs()
      
      expect(result).toEqual(mockJobs)
    })

    it('creates training job', async () => {
      const jobData = { dataset_id: '123', model_type: 'detector', config: {} }
      const mockResponse = { id: '456', ...jobData, status: 'pending' }
      
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse,
      })

      const result = await trainingApi.createJob(jobData)
      
      expect(result).toEqual(mockResponse)
    })
  })

  describe('modelsApi', () => {
    it('lists models', async () => {
      const mockModels = [{ version: 'v1', model_type: 'detector' }]
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => mockModels,
      })

      const result = await modelsApi.list()
      
      expect(result).toEqual(mockModels)
    })

    it('deploys model', async () => {
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => ({ message: 'Deployed successfully' }),
      })

      await modelsApi.deploy('v1')
      
      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:8000/v1/admin/models/v1/deploy',
        expect.objectContaining({ method: 'POST' })
      )
    })
  })

  describe('feedbackApi', () => {
    it('creates feedback', async () => {
      const feedbackData = { prediction_id: '123', is_correct: true }
      const mockResponse = { id: '456', ...feedbackData }
      
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse,
      })

      const result = await feedbackApi.create(feedbackData)
      
      expect(result).toEqual(mockResponse)
    })

    it('gets feedback stats', async () => {
      const mockStats = { total: 100, reviewed: 50, unreviewed: 50 }
      ;(global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => mockStats,
      })

      const result = await feedbackApi.getStats()
      
      expect(result).toEqual(mockStats)
    })
  })
})

