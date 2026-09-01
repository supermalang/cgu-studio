import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from './auth'

// Columns pulled for list/detail views, including the channel variants and
// media each post owns.
const POST_SELECT = `
  *,
  post_variants (
    id, social_account_id, body_override, hashtags_override,
    scheduled_for_override, status, external_url, error_message, published_at,
    social_accounts ( id, platform, handle, display_name, avatar_url )
  ),
  post_media ( id, kind, source, file_url, thumbnail_url, alt_text, position )
`

export const usePostsStore = defineStore('posts', () => {
  const authStore = useAuthStore()

  // State
  const posts = ref([])
  const currentPost = ref(null)
  const loading = ref(false)
  const error = ref(null)

  // Realtime subscription
  let postsChannel = null

  // Computed
  const drafts = computed(() => posts.value.filter(p => p.status === 'draft'))
  const scheduled = computed(() => posts.value.filter(p => p.status === 'scheduled'))
  const needsReview = computed(() => posts.value.filter(p => p.status === 'needs_review'))

  // Posts whose scheduled time has passed but never published — these are the
  // ones a user needs to see first.
  const overdue = computed(() => {
    const now = Date.now()
    return posts.value.filter(
      p => p.status === 'scheduled' && p.scheduled_for && new Date(p.scheduled_for).getTime() < now
    )
  })

  const countsByStatus = computed(() =>
    posts.value.reduce((acc, p) => {
      acc[p.status] = (acc[p.status] || 0) + 1
      return acc
    }, {})
  )

  // Actions
  async function fetchPosts() {
    loading.value = true
    error.value = null

    try {
      const { data, error: fetchError } = await supabase
        .from('posts')
        .select(POST_SELECT)
        .eq('user_id', authStore.user.id)
        .neq('status', 'archived')
        .order('created_at', { ascending: false })

      if (fetchError) throw fetchError
      posts.value = data || []
    } catch (err) {
      console.error('Error fetching posts:', err)
      error.value = err.message
    } finally {
      loading.value = false
    }
  }

  async function fetchPost(id) {
    loading.value = true
    error.value = null

    try {
      const { data, error: fetchError } = await supabase
        .from('posts')
        .select(POST_SELECT)
        .eq('id', id)
        .single()

      if (fetchError) throw fetchError
      currentPost.value = data
      return data
    } catch (err) {
      console.error('Error fetching post:', err)
      error.value = err.message
      return null
    } finally {
      loading.value = false
    }
  }

  // Calendar reads through the RPC so channels and media counts arrive in one
  // round trip instead of N queries per cell.
  async function fetchCalendar(rangeStart, rangeEnd) {
    try {
      const { data, error: rpcError } = await supabase.rpc('get_content_calendar', {
        range_start: rangeStart.toISOString(),
        range_end: rangeEnd.toISOString()
      })

      if (rpcError) throw rpcError
      return data || []
    } catch (err) {
      console.error('Error fetching calendar:', err)
      error.value = err.message
      return []
    }
  }

  async function createPost({ title, body = '', hashtags = [], scheduledFor = null, projectId = null, avatarId = null, environmentId = null }) {
    const userId = authStore.user.id

    const { data, error: insertError } = await supabase
      .from('posts')
      .insert({
        user_id: userId,
        title,
        body,
        hashtags,
        scheduled_for: scheduledFor,
        project_id: projectId,
        avatar_id: avatarId,
        environment_id: environmentId,
        created_by: userId,
        updated_by: userId
      })
      .select(POST_SELECT)
      .single()

    if (insertError) throw insertError

    posts.value.unshift(data)
    return data
  }

  async function updatePost(id, changes) {
    const { data, error: updateError } = await supabase
      .from('posts')
      .update(changes)
      .eq('id', id)
      .select(POST_SELECT)
      .single()

    if (updateError) throw updateError

    applyPostToState(data)
    return data
  }

  async function deletePost(id) {
    const { error: deleteError } = await supabase.from('posts').delete().eq('id', id)
    if (deleteError) throw deleteError

    posts.value = posts.value.filter(p => p.id !== id)
    if (currentPost.value?.id === id) currentPost.value = null
  }

  // Replaces the post's channel set. Variants the user removed are deleted;
  // ones already published are left alone so their permalinks survive.
  async function setChannels(postId, accountIds) {
    const userId = authStore.user.id
    const post = posts.value.find(p => p.id === postId) || currentPost.value
    const existing = post?.post_variants || []

    const toRemove = existing.filter(
      v => !accountIds.includes(v.social_account_id) && v.status !== 'published'
    )
    const existingIds = existing.map(v => v.social_account_id)
    const toAdd = accountIds.filter(id => !existingIds.includes(id))

    if (toRemove.length) {
      const { error: delError } = await supabase
        .from('post_variants')
        .delete()
        .in('id', toRemove.map(v => v.id))
      if (delError) throw delError
    }

    if (toAdd.length) {
      const { error: insError } = await supabase.from('post_variants').insert(
        toAdd.map(accountId => ({
          post_id: postId,
          social_account_id: accountId,
          user_id: userId
        }))
      )
      if (insError) throw insError
    }

    return fetchPost(postId)
  }

  async function updateVariant(variantId, changes) {
    const { error: updateError } = await supabase
      .from('post_variants')
      .update(changes)
      .eq('id', variantId)

    if (updateError) throw updateError
    if (currentPost.value) await fetchPost(currentPost.value.id)
  }

  // Moves the post and every channel to 'scheduled' in one transaction, so the
  // calendar can never show a scheduled post with channels left in draft.
  async function schedulePost(postId, publishAt) {
    const { data, error: rpcError } = await supabase.rpc('schedule_post', {
      target_post_id: postId,
      publish_at: publishAt instanceof Date ? publishAt.toISOString() : publishAt
    })

    if (rpcError) throw rpcError

    await fetchPost(postId)
    return data
  }

  async function attachMedia(postId, media) {
    const userId = authStore.user.id
    const post = posts.value.find(p => p.id === postId) || currentPost.value
    const nextPosition = post?.post_media?.length || 0

    const { data, error: insertError } = await supabase
      .from('post_media')
      .insert({
        post_id: postId,
        user_id: userId,
        kind: media.kind || 'image',
        source: media.source || 'upload',
        file_url: media.fileUrl,
        storage_path: media.storagePath || null,
        thumbnail_url: media.thumbnailUrl || null,
        alt_text: media.altText || null,
        width: media.width || null,
        height: media.height || null,
        file_size_bytes: media.fileSizeBytes || null,
        position: media.position ?? nextPosition,
        environment_id: media.environmentId || null,
        avatar_id: media.avatarId || null,
        n8n_job_id: media.n8nJobId || null
      })
      .select()
      .single()

    if (insertError) throw insertError

    if (currentPost.value?.id === postId) await fetchPost(postId)
    return data
  }

  async function removeMedia(mediaId) {
    const { error: deleteError } = await supabase.from('post_media').delete().eq('id', mediaId)
    if (deleteError) throw deleteError

    if (currentPost.value) await fetchPost(currentPost.value.id)
  }

  function applyPostToState(post) {
    const index = posts.value.findIndex(p => p.id === post.id)
    if (index >= 0) {
      posts.value[index] = { ...posts.value[index], ...post }
    }
    if (currentPost.value?.id === post.id) {
      currentPost.value = { ...currentPost.value, ...post }
    }
  }

  function subscribeToPosts(userId) {
    if (postsChannel) postsChannel.unsubscribe()

    postsChannel = supabase
      .channel('posts-realtime')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'posts', filter: `user_id=eq.${userId}` },
        handlePostChange
      )
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'post_variants', filter: `user_id=eq.${userId}` },
        handleVariantChange
      )
      .subscribe()

    console.log('✅ Subscribed to posts realtime updates')
  }

  function handlePostChange(payload) {
    const { new: newPost, old: oldPost, eventType } = payload

    if (eventType === 'INSERT') {
      // Realtime payloads carry no joined rows, so keep the shape consistent.
      if (!posts.value.some(p => p.id === newPost.id)) {
        posts.value.unshift({ ...newPost, post_variants: [], post_media: [] })
      }
    } else if (eventType === 'UPDATE') {
      applyPostToState(newPost)
    } else if (eventType === 'DELETE') {
      posts.value = posts.value.filter(p => p.id !== oldPost.id)
      if (currentPost.value?.id === oldPost.id) currentPost.value = null
    }
  }

  // A variant changing usually means n8n published or failed a channel, so
  // refetch the parent to pick up the joined account row too.
  function handleVariantChange(payload) {
    const postId = payload.new?.post_id || payload.old?.post_id
    if (!postId) return

    if (currentPost.value?.id === postId) {
      fetchPost(postId)
    }
  }

  function unsubscribe() {
    if (postsChannel) {
      postsChannel.unsubscribe()
      postsChannel = null
      console.log('❌ Unsubscribed from posts realtime')
    }
  }

  function $reset() {
    posts.value = []
    currentPost.value = null
    loading.value = false
    error.value = null
    unsubscribe()
  }

  return {
    // State
    posts,
    currentPost,
    loading,
    error,

    // Computed
    drafts,
    scheduled,
    needsReview,
    overdue,
    countsByStatus,

    // Actions
    fetchPosts,
    fetchPost,
    fetchCalendar,
    createPost,
    updatePost,
    deletePost,
    setChannels,
    updateVariant,
    schedulePost,
    attachMedia,
    removeMedia,
    subscribeToPosts,
    unsubscribe,
    $reset
  }
})
