import Link from 'next/link';
import { Upload, Database, Tag, Brain, Package, MessageSquare, ArrowRight } from 'lucide-react';

const features = [
  {
    name: 'Analyze Image',
    description: 'Upload and analyze amulet images for authenticity verification',
    href: '/analyze',
    icon: Upload,
    color: 'bg-blue-500',
  },
  {
    name: 'Datasets',
    description: 'Manage datasets, upload images, and import from MinIO',
    href: '/admin/datasets',
    icon: Database,
    color: 'bg-green-500',
  },
  {
    name: 'Labeling',
    description: 'Label images for training data preparation',
    href: '/admin/labeling',
    icon: Tag,
    color: 'bg-purple-500',
  },
  {
    name: 'Training',
    description: 'Create and monitor ML model training jobs',
    href: '/admin/training',
    icon: Brain,
    color: 'bg-orange-500',
  },
  {
    name: 'Models',
    description: 'View model versions, evaluate, and deploy models',
    href: '/admin/models',
    icon: Package,
    color: 'bg-red-500',
  },
  {
    name: 'Feedback',
    description: 'Review user feedback and manage retraining',
    href: '/admin/feedback',
    icon: MessageSquare,
    color: 'bg-indigo-500',
  },
];

export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold text-gray-900 mb-4">
            Pra Analysis
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Welcome to the Amulet Authenticity Analysis platform
          </p>
          <p className="text-lg text-gray-500 mt-2">
            Complete ML lifecycle management for amulet authenticity verification
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature) => {
            const Icon = feature.icon;
            return (
              <Link
                key={feature.name}
                href={feature.href}
                className="group relative bg-white rounded-lg shadow-md hover:shadow-xl transition-all duration-300 overflow-hidden"
              >
                <div className="p-6">
                  <div className={`${feature.color} w-12 h-12 rounded-lg flex items-center justify-center mb-4 group-hover:scale-110 transition-transform`}>
                    <Icon className="w-6 h-6 text-white" />
                  </div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-2 group-hover:text-blue-600 transition-colors">
                    {feature.name}
                  </h3>
                  <p className="text-gray-600 text-sm mb-4">
                    {feature.description}
                  </p>
                  <div className="flex items-center text-blue-600 font-medium group-hover:translate-x-1 transition-transform">
                    Get started
                    <ArrowRight className="w-4 h-4 ml-2" />
                  </div>
                </div>
                <div className="absolute inset-0 bg-gradient-to-r from-blue-500/0 to-blue-500/0 group-hover:from-blue-500/5 group-hover:to-transparent transition-all" />
              </Link>
            );
          })}
        </div>

        <div className="mt-12 bg-white rounded-lg shadow-md p-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Quick Start</h2>
          <div className="space-y-4">
            <div className="flex items-start">
              <div className="flex-shrink-0 w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-semibold">
                1
              </div>
              <div className="ml-4">
                <h3 className="font-semibold text-gray-900">Upload Images</h3>
                <p className="text-gray-600 text-sm">
                  Start by uploading images to create a dataset or analyze them directly
                </p>
              </div>
            </div>
            <div className="flex items-start">
              <div className="flex-shrink-0 w-8 h-8 bg-green-100 rounded-full flex items-center justify-center text-green-600 font-semibold">
                2
              </div>
              <div className="ml-4">
                <h3 className="font-semibold text-gray-900">Label Data</h3>
                <p className="text-gray-600 text-sm">
                  Label images as authentic, fake, or uncertain for training
                </p>
              </div>
            </div>
            <div className="flex items-start">
              <div className="flex-shrink-0 w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center text-purple-600 font-semibold">
                3
              </div>
              <div className="ml-4">
                <h3 className="font-semibold text-gray-900">Train Models</h3>
                <p className="text-gray-600 text-sm">
                  Create training jobs to build and improve your ML models
                </p>
              </div>
            </div>
            <div className="flex items-start">
              <div className="flex-shrink-0 w-8 h-8 bg-orange-100 rounded-full flex items-center justify-center text-orange-600 font-semibold">
                4
              </div>
              <div className="ml-4">
                <h3 className="font-semibold text-gray-900">Deploy & Analyze</h3>
                <p className="text-gray-600 text-sm">
                  Deploy models and use them to analyze new images
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
