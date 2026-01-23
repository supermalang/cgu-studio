<script setup>
import { useToast } from '@/composables/useToast'

const { toasts, removeToast } = useToast()

function getToastClasses(type) {
  const baseClasses = 'flex items-center gap-3 p-4 rounded-lg shadow-lg min-w-80 max-w-md'
  const typeClasses = {
    success: 'bg-success-50 text-success-900 border border-success-200',
    error: 'bg-error-50 text-error-900 border border-error-200',
    warning: 'bg-warning-50 text-warning-900 border border-warning-200',
    info: 'bg-primary-50 text-primary-900 border border-primary-200'
  }
  return `${baseClasses} ${typeClasses[type] || typeClasses.info}`
}

function getIconForType(type) {
  const icons = {
    success: '✓',
    error: '✕',
    warning: '⚠',
    info: 'ℹ'
  }
  return icons[type] || icons.info
}
</script>

<template>
  <div class="fixed top-4 right-4 z-50 flex flex-col gap-2">
    <TransitionGroup name="toast">
      <div
        v-for="toast in toasts"
        :key="toast.id"
        :class="getToastClasses(toast.type)"
      >
        <div class="flex-shrink-0 w-5 h-5 flex items-center justify-center font-bold">
          {{ getIconForType(toast.type) }}
        </div>
        <p class="flex-1 text-sm font-medium">{{ toast.message }}</p>
        <button
          @click="removeToast(toast.id)"
          class="flex-shrink-0 text-gray-400 hover:text-gray-600 transition-colors"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </TransitionGroup>
  </div>
</template>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s ease;
}

.toast-enter-from {
  opacity: 0;
  transform: translateX(2rem);
}

.toast-leave-to {
  opacity: 0;
  transform: translateX(2rem) scale(0.95);
}
</style>
