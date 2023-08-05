-- Add default track "Prime Attack" to heist

Hooks:PostHook(MusicManager, "jukebox_default_tracks", "hogar_default_track", function(self)
    self:track_attachment_add("heist_The House Robbery_name", "track_77")	
end)