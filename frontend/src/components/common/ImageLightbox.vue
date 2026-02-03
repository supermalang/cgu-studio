<template>
  <Teleport to="body">
    <Transition name="lightbox-fade">
      <div
        v-if="isOpen"
        class="fixed inset-0 z-50 bg-black/90 flex items-center justify-center"
        @click.self="close"
        @keydown.esc="close"
        tabindex="-1"
      >
        <!-- Close Button (top-right) -->
        <button
          @click="close"
          class="absolute top-4 right-4 w-10 h-10 rounded-full bg-white/10 hover:bg-white/20 text-white text-2xl"
        >
          ×
        </button>

        <!-- Image Container (with drag support) -->
        <div
          class="relative select-none"
          @mousedown="startDrag"
          @mousemove="drag"
          @mouseup="endDrag"
          @mouseleave="endDrag"
          @wheel.prevent="handleWheel"
        >
          <img
            :src="imageUrl"
            :style="imageStyle"
            class="max-w-none cursor-move user-select-none"
            draggable="false"
          />
        </div>

        <!-- Zoom Controls (bottom-center) -->
        <div class="absolute bottom-6 left-1/2 transform -translate-x-1/2">
          <div class="flex items-center gap-3 bg-black/80 backdrop-blur rounded-lg px-4 py-2 text-white">
            <button
              @click="zoomOut"
              :disabled="zoom <= 0.5"
              class="w-8 h-8 rounded hover:bg-white/20 disabled:opacity-30"
            >
              <span class="text-xl">−</span>
            </button>

            <span class="min-w-[60px] text-center font-medium">{{ Math.round(zoom * 100) }}%</span>

            <button
              @click="zoomIn"
              :disabled="zoom >= 3"
              class="w-8 h-8 rounded hover:bg-white/20 disabled:opacity-30"
            >
              <span class="text-xl">+</span>
            </button>

            <button @click="resetZoom" class="px-3 py-1 rounded hover:bg-white/20 text-sm">
              Reset
            </button>
          </div>
        </div>

        <!-- Image Info (top-left) -->
        <div
          v-if="imageInfo"
          class="absolute top-4 left-4 bg-black/80 backdrop-blur text-white px-4 py-2 rounded-lg"
        >
          <div class="text-sm font-medium">{{ imageInfo }}</div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, computed, watch } from 'vue'

const props = defineProps({
  isOpen: Boolean,
  imageUrl: String,
  imageInfo: String
})

const emit = defineEmits(['close'])

// Zoom state
const zoom = ref(1)
const panX = ref(0)
const panY = ref(0)

// Drag state
const isDragging = ref(false)
const dragStartX = ref(0)
const dragStartY = ref(0)
const lastPanX = ref(0)
const lastPanY = ref(0)

// Computed style for image transform
const imageStyle = computed(() => ({
  transform: `scale(${zoom.value}) translate(${panX.value}px, ${panY.value}px)`,
  transition: isDragging.value ? 'none' : 'transform 0.2s ease'
}))

// Watch for lightbox open/close
watch(
  () => props.isOpen,
  (newVal) => {
    if (newVal) {
      // Focus the lightbox for keyboard events
      setTimeout(() => {
        const lightbox = document.querySelector('.fixed.inset-0')
        if (lightbox) lightbox.focus()
      }, 100)
    } else {
      resetZoom()
    }
  }
)

function close() {
  emit('close')
}

function zoomIn() {
  zoom.value = Math.min(zoom.value + 0.5, 3)
}

function zoomOut() {
  zoom.value = Math.max(zoom.value - 0.5, 0.5)
  // Reset pan when zooming out to 100% or less
  if (zoom.value <= 1) {
    panX.value = 0
    panY.value = 0
  }
}

function resetZoom() {
  zoom.value = 1
  panX.value = 0
  panY.value = 0
}

function handleWheel(e) {
  // Zoom with mouse wheel
  if (e.deltaY < 0) {
    zoomIn()
  } else {
    zoomOut()
  }
}

function startDrag(e) {
  if (zoom.value <= 1) return // Only allow drag when zoomed in
  isDragging.value = true
  dragStartX.value = e.clientX
  dragStartY.value = e.clientY
  lastPanX.value = panX.value
  lastPanY.value = panY.value
}

function drag(e) {
  if (!isDragging.value) return

  const deltaX = e.clientX - dragStartX.value
  const deltaY = e.clientY - dragStartY.value

  panX.value = lastPanX.value + deltaX / zoom.value
  panY.value = lastPanY.value + deltaY / zoom.value
}

function endDrag() {
  isDragging.value = false
}
</script>

<style scoped>
.lightbox-fade-enter-active,
.lightbox-fade-leave-active {
  transition: opacity 0.2s ease;
}

.lightbox-fade-enter-from,
.lightbox-fade-leave-to {
  opacity: 0;
}

.user-select-none {
  user-select: none;
  -webkit-user-select: none;
  -moz-user-select: none;
}
</style>
