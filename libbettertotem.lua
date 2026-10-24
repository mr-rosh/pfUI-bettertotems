-- load pfUI environment
setfenv(1, pfUI:GetEnvironment())

-- return instantly if we're not on a vanilla client
if pfUI.client > 11200 then return end
if LibBetterTotem then return end


MAX_TOTEMS       = MAX_TOTEMS       or 4
FIRE_TOTEM_SLOT  = FIRE_TOTEM_SLOT  or 1
EARTH_TOTEM_SLOT = EARTH_TOTEM_SLOT or 2
WATER_TOTEM_SLOT = WATER_TOTEM_SLOT or 3
AIR_TOTEM_SLOT   = AIR_TOTEM_SLOT   or 4

local _, class = UnitClass("player")

local libtotem = CreateFrame("Frame")
local nameIconMap = {}
local queue = { ["slot"] = nil, ["name"] = nil, ["start"] = nil, ["duration"] = nil, ["icon"] = nil }
local active = { [1] = {}, [2] = {}, [3] = {}, [4] = {} }

-- Always expose the lib (even for non-shamans) so dependent modules can call
-- LibBetterTotem.HasTotemicMastery() safely.
LibBetterTotem = libtotem
local totems = {
  [FIRE_TOTEM_SLOT] = {
    --Fire Nova Totem (Fire)
    ["Spell_Fire_SealOfFire"] = {[-1] = 5},
    --Flametongue Totem (Fire)
    ["Spell_Nature_GuardianWard"] = {[-1] = 120},
    --Frost Resistance Totem (Fire)
    ["Spell_FrostResistanceTotem_01"] = {[-1] = 120},
    --Magma Totem (Fire)
    ["Spell_Fire_SelfDestruct"] = {[-1] = 20},
    --Searing Totem (Fire)
    ["Spell_Fire_SearingTotem"] = {[-1] = 55,[1] = 30,[2] = 35,[3] = 40,[4] = 45,[5] = 50,[6] = 55},
  },
  [EARTH_TOTEM_SLOT] = {
    --Earthbind Totem (Earth)
    ["Spell_Nature_StrengthOfEarthTotem02"] = {[-1] = 45},
    --Stoneclaw Totem (Earth)
    ["Spell_Nature_StoneClawTotem"] = {[-1] = 15},
    --Stoneskin Totem (Earth)
    ["Spell_Nature_StoneSkinTotem"] = {[-1] = 120},
    --Strength of Earth Totem (Earth)
    ["Spell_Nature_EarthBindTotem"] = {[-1] = 120},
    --Tremor Totem (Earth)
    ["Spell_Nature_TremorTotem"] = {[-1] = 120},
  },
  [WATER_TOTEM_SLOT] = {
    -- Disease Cleansing Totem (Water)
    ["Spell_Nature_DiseaseCleansingTotem"] = {[-1] = 120},
    --Fire Resistance Totem (Water)
    ["Spell_FireResistanceTotem_01"] = {[-1] = 120},
    --Healing Stream Totem (Water)
    ["INV_Spear_04"] = {[-1] = 60},
    --Mana Spring Totem (Water)
    ["Spell_Nature_ManaRegenTotem"] = {[-1] = 60},
    --Mana Tide Totem (Water)
    ["Spell_Frost_SummonWaterElemental"] = {[-1] = 12},
    --Poison Cleansing Totem (Water)
    ["Spell_Nature_PoisonCleansingTotem"] = {[-1] = 120},
  },
  [AIR_TOTEM_SLOT] = {
    --Grace of Air Totem (Air)
    ["Spell_Nature_InvisibilityTotem"] = {[-1] = 120},
    --Grounding Totem (Air)
    ["Spell_Nature_GroundingTotem"] = {[-1] = 45},
    --Nature Resistance Totem (Air)
    ["Spell_Nature_NatureResistanceTotem"] = {[-1] = 120},
    --Tranquil Air Totem (Air)
    ["Spell_Nature_Brilliance"] = {[-1] = 120},
    --Windfury Totem (Air)
    ["Spell_Nature_Windfury"] = {[-1] = 120},
    --Windwall Totem (Air)
    ["Spell_Nature_EarthBind"] = {[-1] = 120},
  },
}

-- Cache the totemic mastery talent rank so we don't call GetTalentInfo on every
-- refresh (RefreshList runs every 0.5s on vanilla via the OnUpdate emulator).
local totemicMasteryRank = nil
local function UpdateTotemicMastery()
  if totemicMasteryRank == nil then
    local _, _, _, _, rank = GetTalentInfo(3, 8)
    totemicMasteryRank = rank == 1
  end
  return totemicMasteryRank
end

-- Exposed on libtotem; LibBetterTotem aliases it below.
libtotem.HasTotemicMastery = UpdateTotemicMastery
-- Prime the cache on load.
UpdateTotemicMastery()

GetBetterTotemInfo = function(id)
  local a = active[id]
  if not a or not a.name then return end
  if GetRemainingDuration(id) < 0 or IsTotemDestroyed(id) then
    libtotem:Clean(id)
    return nil
  end

  return 1, a.name, a.start, a.duration, a.icon, a.unitId
end

if class ~= "SHAMAN" then return end

libtotem:RegisterEvent("SPELLCAST_STOP")
libtotem:RegisterEvent("UNIT_MODEL_CHANGED")
libtotem:RegisterEvent("PLAYER_DEAD")
libtotem:SetScript("OnEvent", function()
  -- Capture event/arg1 into locals (Classic 1.12-safe).
  local event, arg1 = event, arg1

  if event == "PLAYER_DEAD" then
    for i = 1, 4 do
      libtotem:Clean(i)
    end
  elseif event == "UNIT_MODEL_CHANGED" then
    local unitId = arg1
    local unitName = unitId and UnitName(unitId)

    if unitName and string.find(unitName, "Totem") then
      local ownerId = unitId .. "owner"
      local ownerName = UnitName(ownerId)
      if ownerName and ownerName == UnitName("player") then
        local key = GetKeyIndexIfExists(nameIconMap, unitName)
        if key then
          local icon = nameIconMap[key]
          local slot = GetTotemSlot(icon)
          if slot and active[slot] then
            active[slot].unitId = unitId
          end
        end
      end
    end
  elseif event == "SPELLCAST_STOP" then
    if queue.slot and queue.name then
      local a = active[queue.slot]
      if a then
        a.name = queue.name
        a.duration = queue.duration
        a.icon = queue.icon
        a.start = GetTime()
      end
      queue.slot = nil
      queue.name = nil
    end
  end
end)

libtotem.totems = totems

libtotem.Clean = function(self, slot)
  local a = active[slot]
  if not a then return end
  a.name = nil
  a.start = nil
  a.duration = nil
  a.icon = nil
  a.unitId = nil
end

libtotem.CheckAddQueue = function(self, name, rank, icon)
  if not name or not icon then return nil end
  for slot = 1, 4 do
    for texture, data in pairs(totems[slot]) do
      if string.find(icon, texture, 1) then
        if rank then -- try to obtain plain rank number
          _, _, rank = string.find(rank, "%s(%d+)")
        end
        queue.slot = slot
        queue.name = name
        queue.icon = icon
        nameIconMap[name] = icon
        if rank and tonumber(rank) and data[tonumber(rank)] then
          queue.duration = data[tonumber(rank)]
        else
          queue.duration = data[-1]
        end
        return true
      end
    end
  end
  return nil
end

function GetKeyIndexIfExists(table, contains)
  local index = nil
  if table and contains and type(table) == "table" then
    for k, v in pairs(table) do
      if string.find(contains, k) then
        index = k
      end
    end
  end
  return index
end

function GetTotemSlot(icon)
  if not icon then return nil end
  for slot = 1, 4 do
    for texture, data in pairs(totems[slot]) do
      if string.find(icon, texture, 1) then
        return slot
      end
    end
  end
  return nil
end

function IsTotemTransition(id)
  local a = active[id]
  if not a then return false end
  -- Transitioning when: unitId set but no name yet, OR name set but no unitId,
  -- OR a spell cast is queued. Parenthesized for clarity (and binds correctly).
  if (a.unitId and a.name == nil) or (a.unitId == nil and a.name) or (queue.name ~= nil) then
    return true
  end
  return false
end

function IsTotemDestroyed(id)
  local a = active[id]
  if not a then return false end
  if IsTotemTransition(id) then return false end
  if not a.duration or not a.start then return false end
  -- Destroyed when the totem unit doesn't exist in the world and more than
  -- 1 second has passed since the cast (totem failed to spawn or was removed).
  if not a.unitId or not UnitExists(a.unitId) then
    local remaining = GetRemainingDuration(id)
    if not remaining then return false end
    if a.duration - remaining > 1 then -- GetTime() - start > 1
      return true
    end
  end
  return false
end

function GetRemainingDuration(id)
  local a = active[id]
  if not a or not a.start or not a.duration then return 0 end
  return a.start + a.duration - GetTime()
end


-- Check for totem spell casts
hooksecurefunc("CastSpell", function(id, bookType)
  local name, rank, icon = libspell.GetSpellInfo(id, bookType)
  if not name then return end
  if libtotem:CheckAddQueue(name, rank, icon) then return end
end)

hooksecurefunc("CastSpellByName", function(effect, target)
  local name, rank, icon = libspell.GetSpellInfo(effect)
  if not name then return end
  if libtotem:CheckAddQueue(name, rank, icon) then return end
end)

local scanner = libtipscan:GetScanner("prediction")
hooksecurefunc("UseAction", function(slot, target, selfcast)
  if GetActionText(slot) or not IsCurrentAction(slot) then return end
  scanner:SetAction(slot)
  local name, rank = scanner:Line(1)
  local icon = GetActionTexture(slot)
  if not name then return end
  if libtotem:CheckAddQueue(name, rank, icon) then return end
end)
