local t = {}
local abstractUpgradeMonsterAfterPlayerStepsWorldEffect = require("classes.world.effects.world.abstractUpgradeMonsterAfterPlayerStepsWorldEffect")

function t:new(_saveableOptions, _monster, _selectedTraitUID)
  local effect = abstractUpgradeMonsterAfterPlayerStepsWorldEffect:new(_saveableOptions, _monster, 5)
  effect.classes.traitRerollWorldEffect = true
  if _monster then
    local _monster = _monster
    _saveableOptions.originalTraitUID = _monster:getTraitUID()
    _monster:setTraitByUID(_selectedTraitUID)
  end
  
  function effect:getClassPath()
    return "classes.world.effects.world.traitRerollWorldEffect"
  end
  
  function effect:getReachedTargetPlayerStepsPhoneMessageUID()
    return "electricTown_ROMAN.reroll_ready"
  end
  
  function effect:getOriginalTraitUID()
    return _saveableOptions.originalTraitUID
  end
  
  return effect
end

return t
