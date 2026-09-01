<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { usePostsStore } from '@/stores/posts'
import { useSocialAccountsStore } from '@/stores/socialAccounts'
import { useToast } from '@/composables/useToast'
import { getPlatform, getStatus, checkCaptionLength } from '@/lib/platforms'
import Sidebar from '@/components/common/Sidebar.vue'
import AppHeader from '@/components/common/AppHeader.vue'
import ChannelVariantEditor from '@/components/content/ChannelVariantEditor.vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const postsStore = usePostsStore()
const accountsStore = useSocialAccountsStore()
const { showToast } = useToast()

const isLoading = ref(true)
const isSaving = ref(false)
const error = ref(null)

const isNew = computed(() => route.name === 'post-create')
const post = computed(() => postsStore.currentPost)

// Draft form state, kept separate from the store so a failed save doesn't
// leave the UI showing values the database never accepted.
const form = ref({ title: '', body: '', hashtags: '', scheduledFor: '' })
const selectedAccountIds = ref([])

const accounts = computed(() => accountsStore.activeAccounts)

// Caption length is checked per selected channel, since limits differ wildly
// (280 on X vs 2200 on Instagram).
const captionWarnings = computed(() =>
  accounts.value
    .filter(a => selectedAccountIds.value.includes(a.id))
    .map(a => ({ account: a, check: checkCaptionLength(a.platform, form.value.body) }))
    .filter(entry => entry.check.exceeded)
)

const canSchedule = computed(
  () => selectedAccountIds.value.length > 0 && !!form.value.scheduledFor && !captionWarnings.value.length
)

function toLocalInput(iso) {
  if (!iso) return ''
  const d = new Date(iso)
  const pad = n => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

function hydrateForm(data) {
  form.value = {
    title: data.title || '',
    body: data.body || '',
    hashtags: (data.hashtags || []).join(' '),
    scheduledFor: toLocalInput(data.scheduled_for)
  }
  selectedAccountIds.value = (data.post_variants || []).map(v => v.social_account_id)
}

function parseHashtags(raw) {
  return raw
    .split(/[\s,]+/)
    .map(t => t.replace(/^#/, '').trim())
    .filter(Boolean)
}

async function load() {
  isLoading.value = true
  error.value = null

  try {
    await accountsStore.fetchAccounts()

    if (isNew.value) {
      postsStore.currentPost = null
      form.value.scheduledFor = toLocalInput(route.query.scheduled_for)
    } else {
      const data = await postsStore.fetchPost(route.params.id)
      if (!data) throw new Error('Post not found')
      hydrateForm(data)
    }
  } catch (err) {
    console.error('Error loading post:', err)
    error.value = err.message
    showToast('Failed to load this post.', 'error')
  } finally {
    isLoading.value = false
  }
}

async function save({ silent = false } = {}) {
  if (!form.value.title.trim()) {
    showToast('Give the post an internal title first.', 'warning')
    return null
  }

  isSaving.value = true

  try {
    const payload = {
      title: form.value.title.trim(),
      body: form.value.body,
      hashtags: parseHashtags(form.value.hashtags),
      scheduled_for: form.value.scheduledFor ? new Date(form.value.scheduledFor).toISOString() : null
    }

    let saved
    if (isNew.value) {
      saved = await postsStore.createPost({
        title: payload.title,
        body: payload.body,
        hashtags: payload.hashtags,
        scheduledFor: payload.scheduled_for
      })
      await postsStore.setChannels(saved.id, selectedAccountIds.value)
      // Swap to the edit route so later saves update instead of inserting.
      await router.replace({ name: 'post-edit', params: { id: saved.id } })
    } else {
      saved = await postsStore.updatePost(route.params.id, payload)
      await postsStore.setChannels(route.params.id, selectedAccountIds.value)
    }

    if (!silent) showToast('Post saved.', 'success')
    return saved
  } catch (err) {
    console.error('Error saving post:', err)
    showToast(`Could not save the post: ${err.message}`, 'error')
    return null
  } finally {
    isSaving.value = false
  }
}

async function schedule() {
  const saved = await save({ silent: true })
  if (!saved) return

  try {
    await postsStore.schedulePost(saved.id || route.params.id, new Date(form.value.scheduledFor))
    showToast('Post scheduled across all channels.', 'success')
  } catch (err) {
    console.error('Error scheduling post:', err)
    showToast(`Could not schedule: ${err.message}`, 'error')
  }
}

async function submitForReview() {
  const saved = await save({ silent: true })
  if (!saved) return

  try {
    await postsStore.updatePost(saved.id || route.params.id, { status: 'needs_review' })
    showToast('Sent for review.', 'success')
  } catch (err) {
    showToast(`Could not update status: ${err.message}`, 'error')
  }
}

function toggleAccount(id) {
  const index = selectedAccountIds.value.indexOf(id)
  if (index >= 0) selectedAccountIds.value.splice(index, 1)
  else selectedAccountIds.value.push(id)
}

watch(() => route.params.id, () => { if (!isNew.value) load() })

onMounted(async () => {
  await load()
  if (authStore.user?.id) postsStore.subscribeToPosts(authStore.user.id)
})

onUnmounted(() => postsStore.unsubscribe())
</script>

<template>
  <div class="min-h-screen bg-neutral-50">
    <Sidebar />
    <AppHeader />

    <main class="ml-64 px-6 py-8">
      <div v-if="isLoading" class="card p-12 text-center text-neutral-500">Loading…</div>

      <template v-else>
        <!-- Header -->
        <div class="flex items-start justify-between mb-8">
          <div>
            <router-link :to="{ name: 'calendar' }" class="text-sm text-neutral-500 hover:text-primary-600">
              ← Back to calendar
            </router-link>
            <h1 class="text-4xl font-black text-neutral-900 mt-2">
              {{ isNew ? 'New post' : form.title || 'Untitled post' }}
            </h1>
            <span
              v-if="post"
              class="inline-block mt-2 text-xs px-2 py-1 rounded-full font-medium"
              :class="getStatus(post.status).class"
            >
              {{ getStatus(post.status).label }}
            </span>
          </div>

          <div class="flex items-center gap-2">
            <button @click="save()" :disabled="isSaving" class="btn-secondary">
              {{ isSaving ? 'Saving…' : 'Save draft' }}
            </button>
            <button @click="submitForReview" :disabled="isSaving" class="btn-ghost">
              Send for review
            </button>
            <button @click="schedule" :disabled="!canSchedule || isSaving" class="btn-primary">
              Schedule
            </button>
          </div>
        </div>

        <div v-if="error" class="card p-4 mb-4 bg-error-50 text-error-700">{{ error }}</div>

        <div class="grid grid-cols-3 gap-6">
          <!-- Composer -->
          <div class="col-span-2 space-y-6">
            <div class="card p-6 space-y-4">
              <div>
                <label class="input-label" for="post-title">Internal title</label>
                <input
                  id="post-title"
                  v-model="form.title"
                  class="input-field"
                  placeholder="Launch teaser — week 1"
                />
                <p class="text-xs text-neutral-500 mt-1">Shown on the calendar only. Never published.</p>
              </div>

              <div>
                <label class="input-label" for="post-body">Caption</label>
                <textarea
                  id="post-body"
                  v-model="form.body"
                  rows="8"
                  class="input-field"
                  placeholder="Write the caption every channel starts from…"
                />
              </div>

              <div>
                <label class="input-label" for="post-tags">Hashtags</label>
                <input
                  id="post-tags"
                  v-model="form.hashtags"
                  class="input-field"
                  placeholder="launch ai behindthescenes"
                />
                <p class="text-xs text-neutral-500 mt-1">Space separated. The # is optional.</p>
              </div>

              <div>
                <label class="input-label" for="post-when">Publish at</label>
                <input id="post-when" v-model="form.scheduledFor" type="datetime-local" class="input-field" />
              </div>

              <!-- Per-channel caption overruns block scheduling -->
              <div v-if="captionWarnings.length" class="rounded-lg bg-error-50 text-error-700 p-3 text-sm">
                <p class="font-semibold mb-1">Caption too long for some channels:</p>
                <ul class="list-disc list-inside">
                  <li v-for="w in captionWarnings" :key="w.account.id">
                    {{ getPlatform(w.account.platform).label }} {{ w.account.handle }} — {{ w.check.message }}
                  </li>
                </ul>
                <p class="mt-1">Shorten the caption, or override it per channel below.</p>
              </div>
            </div>

            <!-- Per-channel overrides, only meaningful once the post exists -->
            <ChannelVariantEditor
              v-if="post && post.post_variants?.length"
              :post="post"
              :base-body="form.body"
            />
          </div>

          <!-- Channel picker -->
          <div class="space-y-6">
            <div class="card p-6">
              <h2 class="font-bold text-neutral-900 mb-1">Channels</h2>
              <p class="text-xs text-neutral-500 mb-4">Pick where this post goes.</p>

              <p v-if="!accounts.length" class="text-sm text-neutral-500">
                No channels connected yet.
                <router-link :to="{ name: 'social-accounts' }" class="text-primary-600 font-medium">
                  Connect one
                </router-link>
              </p>

              <label
                v-for="account in accounts"
                :key="account.id"
                class="flex items-center gap-3 py-2 cursor-pointer"
              >
                <input
                  type="checkbox"
                  :checked="selectedAccountIds.includes(account.id)"
                  @change="toggleAccount(account.id)"
                  class="rounded border-neutral-300"
                />
                <span
                  class="w-2.5 h-2.5 rounded-full"
                  :style="{ backgroundColor: getPlatform(account.platform).color }"
                />
                <span class="text-sm font-medium text-neutral-900">
                  {{ getPlatform(account.platform).label }}
                </span>
                <span class="text-sm text-neutral-500 truncate">{{ account.handle }}</span>
              </label>
            </div>

            <!-- Media -->
            <div class="card p-6">
              <h2 class="font-bold text-neutral-900 mb-1">Media</h2>
              <p class="text-xs text-neutral-500 mb-4">
                Attach images, or generate them from an avatar and environment.
              </p>

              <div v-if="post?.post_media?.length" class="grid grid-cols-3 gap-2 mb-3">
                <img
                  v-for="media in post.post_media"
                  :key="media.id"
                  :src="media.thumbnail_url || media.file_url"
                  :alt="media.alt_text || ''"
                  class="w-full aspect-square object-cover rounded-lg"
                />
              </div>
              <p v-else class="text-sm text-neutral-500">No media attached yet.</p>
            </div>
          </div>
        </div>
      </template>
    </main>
  </div>
</template>
