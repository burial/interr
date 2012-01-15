local mod = CreateFrame('frame', 'interr')
mod:SetScript('OnEvent', function(self, event, ...) return self[event](self, ...) end)
mod:RegisterEvent('PLAYER_ENTERING_WORLD')

local me -- player guid
local casts = { }

local links = setmetatable({ }, {
  __index = function(self, index)
    local value = GetSpellLink(index)
    rawset(self, index, value)
    return value
  end
})

local function alert(...)
  local message = string.format("%sed %s's %s (%s) %2.2fs into cast", ...)
  local facet = GetNumPartyMembers() > 0 and 'PARTY' or 'SAY'
  SendChatMessage(message, facet)
  return true
end

function mod:PLAYER_ENTERING_WORLD()
  self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
  me = UnitGUID('player')
  self.PLAYER_ENTERING_WORLD = function() wipe(casts) end
  return true
end

do
  local schools = { 'Physical', 'Holy', 'Fire', 'Nature', 'Frost', 'Shadow', 'Arcane'}
  function mod:COMBAT_LOG_EVENT_UNFILTERED(time, kind, hideCaster,
                                           srcGUID, srcName, srcFlags, srcRaidFlags,
                                           dstGUID, dstName, dstFlags, dstRaidFlags,
                                           spellID, spellName, spellSchool,
                                           extraSpellID, extraSpellName, extraSpellSchool)
    if kind == 'SPELL_CAST_START' then
      casts[srcGUID] = time
    elseif kind == 'SPELL_CAST_SUCCESS' or kind == 'SPELL_CAST_FAILED' then
      casts[srcGUID] = nil
    elseif kind == 'SPELL_INTERRUPT' and srcGUID == me then
      alert(links[spellID], dstName, links[extraSpellID], schools[extraSpellSchool], time - casts[dstGUID])
    end

    return true
  end
end
