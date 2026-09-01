<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { usePostsStore } from '@/stores/posts'
import { useToast } from '@/composables/useToast'
import { getPlatform, getStatus } from '@/lib/platforms'
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'

const router = useRouter()
const authStore = useAuthStore()
const postsStore = usePostsStore()
const { showToast } = useToast()

const isLoading = ref(true)
const error = ref(null)
const cursor = ref(startOfMonth(new Date()))
const calendarPosts = ref([])

function startOfMonth(date) {
  return new Date(date.getFullYear(), date.getMonth(), 1)
}

// The grid always starts on the Monday on or before the 1st, so weeks line up.
const gridStart = computed(() => {
  const first = cursor.value
  const offset = (first.getDay() + 6) % 7
  return new Date(first.getFullYear(), first.getMonth(), 1 - offset)
})

// Six weeks covers every possible month layout without the grid reflowing.
const days = computed(() => {
  const start = gridStart.value
  return Array.from({ length: 42 }, (_, i) => {
    const date = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
    return {
      date,
      key: date.toDateString(),
      dayNumber: date.getDate(),
      inMonth: date.getMonth() === cursor.value.getMonth(),
      isToday: date.toDateString() === new Date().toDateString(),
      posts: postsForDay(date)
    }
  })
})

const monthLabel = computed(() =>
  cursor.value.toLocaleDateString(undefined, { month: 'long', year: 'numeric' })
)

const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

function postsForDay(date) {
  const key = date.toDateString()
  return calendarPosts.value.filter(p => {
    const when = p.scheduled_for || p.published_at
    return when && new Date(when).toDateString() === key
  })
}

async function loadCalendar() {
  isLoading.value = true
  error.value = null

  try {
    const start = gridStart.value
    const end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 42)
    calendarPosts.value = await postsStore.fetchCalendar(start, end)
  } catch (err) {
    console.error('Error loading calendar:', err)
    error.value = 'Failed to load the content calendar'
    showToast('Failed to load the content calendar.', 'error')
  } finally {
    isLoading.value = false
  }
}

function shiftMonth(delta) {
  cursor.value = new Date(cursor.value.getFullYear(), cursor.value.getMonth() + delta, 1)
  loadCalendar()
}

function goToToday() {
  cursor.value = startOfMonth(new Date())
  loadCalendar()
}

function openPost(post) {
  router.push({ name: 'post-edit', params: { id: post.id } })
}

// New posts land pre-scheduled at 9am on the day the user clicked.
function createOnDay(date) {
  const at = new Date(date)
  at.setHours(9, 0, 0, 0)
  router.push({ name: 'post-create', query: { scheduled_for: at.toISOString() } })
}

function timeLabel(post) {
  const when = post.scheduled_for || post.published_at
  if (!when) return ''
  return new Date(when).toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' })
}

onMounted(async () => {
  await loadCalendar()
  if (authStore.user?.id) postsStore.subscribeToPosts(authStore.user.id)
})

onUnmounted(() => postsStore.unsubscribe())
</script>

<template>
  <div class="min-h-screen bg-neutral-50">
    <Sidebar />
    <AppHeader />

    <main class="ml-64 px-6 py-8">
      <!-- Page Header -->
      <div class="flex items-start justify-between mb-8">
        <div>
          <h1 class="text-4xl font-black text-neutral-900 mb-2">Content Calendar</h1>
          <p class="text-base text-neutral-600">
            Plan, review, and schedule your posts across every channel.
          </p>
        </div>
        <router-link :to="{ name: 'post-create' }" class="btn-primary">
          New post
        </router-link>
      </div>

      <!-- Month controls -->
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center gap-2">
          <button @click="shiftMonth(-1)" class="btn-ghost px-3" aria-label="Previous month">‹</button>
          <span class="text-lg font-bold text-neutral-900 min-w-48 text-center">{{ monthLabel }}</span>
          <button @click="shiftMonth(1)" class="btn-ghost px-3" aria-label="Next month">›</button>
          <button @click="goToToday" class="btn-ghost text-sm">Today</button>
        </div>
        <div class="text-sm text-neutral-500">
          {{ calendarPosts.length }} post{{ calendarPosts.length === 1 ? '' : 's' }} this view
        </div>
      </div>

      <!-- Error -->
      <div v-if="error" class="card p-4 mb-4 bg-error-50 text-error-700">{{ error }}</div>

      <!-- Loading -->
      <div v-if="isLoading" class="card p-12 text-center text-neutral-500">
        Loading calendar…
      </div>

      <!-- Calendar grid -->
      <div v-else class="card overflow-hidden">
        <div class="grid grid-cols-7 border-b border-neutral-200">
          <div
            v-for="day in weekdays"
            :key="day"
            class="px-3 py-2 text-xs font-bold uppercase tracking-wide text-neutral-500"
          >
            {{ day }}
          </div>
        </div>

        <div class="grid grid-cols-7">
          <div
            v-for="day in days"
            :key="day.key"
            class="min-h-32 border-b border-r border-neutral-100 p-2 group"
            :class="day.inMonth ? 'bg-white' : 'bg-neutral-50/60'"
          >
            <div class="flex items-center justify-between mb-1">
              <span
                class="text-xs font-semibold w-6 h-6 flex items-center justify-center rounded-full"
                :class="day.isToday
                  ? 'bg-primary-600 text-white'
                  : day.inMonth ? 'text-neutral-700' : 'text-neutral-400'"
              >
                {{ day.dayNumber }}
              </span>
              <button
                @click="createOnDay(day.date)"
                class="opacity-0 group-hover:opacity-100 text-neutral-400 hover:text-primary-600 text-lg leading-none transition-opacity"
                :aria-label="`Add a post on ${day.date.toDateString()}`"
              >
                +
              </button>
            </div>

            <button
              v-for="post in day.posts"
              :key="post.id"
              @click="openPost(post)"
              class="w-full text-left mb-1 px-2 py-1 rounded-lg bg-neutral-50 hover:bg-primary-50 border border-neutral-200 transition-colors"
            >
              <div class="flex items-center gap-1 mb-0.5">
                <span
                  v-for="channel in post.channels"
                  :key="channel.variant_id"
                  class="w-2 h-2 rounded-full shrink-0"
                  :style="{ backgroundColor: getPlatform(channel.platform).color }"
                  :title="`${getPlatform(channel.platform).label} ${channel.handle}`"
                />
                <span class="text-[10px] text-neutral-500 ml-auto">{{ timeLabel(post) }}</span>
              </div>
              <div class="text-xs font-semibold text-neutral-900 truncate">{{ post.title }}</div>
              <span
                class="inline-block mt-1 text-[10px] px-1.5 py-0.5 rounded-full font-medium"
                :class="getStatus(post.status).class"
              >
                {{ getStatus(post.status).label }}
              </span>
            </button>

            <!-- Empty day -->
            <p
              v-if="day.inMonth && !day.posts.length"
              class="text-[11px] text-neutral-300 mt-1"
            >
              &nbsp;
            </p>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>
