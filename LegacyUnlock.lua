-- Legacy Unlock: WoW Forever's Legacy window, open at Legacy level 0 too.
--
-- Blizzard's ToggleLegacySystemUI -- what the Legacy key binding and the
-- Legacy micro button call (Blizzard_LegacySystem_Bootstrap.lua, loaded at
-- startup) -- returns while the Legacy reward track's renown level is 0, and
-- the micro button disables itself while the system is locked. So a character
-- with no Legacy points cannot look at the window at all. Nothing else checks
-- the level: ToggleLegacyChallenges loads and opens the same window, on its
-- challenges tab.
--
-- Everything here is a post-hook (hooksecurefunc): Blizzard's functions are
-- left exactly as they are, and only add to what they did.

local _G = _G
local hooksecurefunc = hooksecurefunc

-- The Legacy level, or nil on a client without the Legacy system.
local function LegacyLevel()
  local consts = _G.Constants and _G.Constants.LegacyConsts
  local factions = _G.C_MajorFactions
  if not (consts and factions and factions.GetCurrentRenownLevel) then return end
  return factions.GetCurrentRenownLevel(consts.LEGACY_REWARD_TRACK_FACTION_ID)
end

local function Locked()
  local level = LegacyLevel()
  return level ~= nil and level <= 0
end

if not (_G.ToggleLegacySystemUI and _G.ToggleLegacyChallenges) then return end

-- The key binding and the micro button: after Blizzard's toggle returned
-- without doing anything, toggle the window the other way.
hooksecurefunc("ToggleLegacySystemUI", function()
  if Locked() then _G.ToggleLegacyChallenges() end
end)

-- The micro button disables itself while locked, and a disabled button never
-- runs its click. After each of its own updates it is enabled again and
-- pressed while the window is open, as it is once unlocked. Blizzard's
-- "disable every micro button" (behind full-screen panels) does not go
-- through this update, so that still applies.
local button = _G.LegacyMicroButton
if button and button.UpdateMicroButton then
  hooksecurefunc(button, "UpdateMicroButton", function(self)
    if not Locked() then return end
    self:Enable()
    self.disabledTooltip = nil
    local frame = _G.LegacySystemFrame
    if frame and frame:IsShown() then
      self:SetPushed()
    else
      self:SetNormal()
    end
  end)

  -- Once the game is up, so the first look at the button does not wait for
  -- Blizzard's next micro menu update.
  local loader = _G.CreateFrame("Frame")
  loader:RegisterEvent("PLAYER_ENTERING_WORLD")
  loader:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if _G.UpdateMicroButtons then _G.UpdateMicroButtons() end
  end)
end
