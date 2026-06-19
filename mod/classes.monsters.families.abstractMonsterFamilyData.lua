local t = {}
local abstractMonsterFamilyDataMeta = {}

function t:new()
  local abstractMonsterFamilyData = {}
  setmetatable(abstractMonsterFamilyData, {__index = abstractMonsterFamilyDataMeta})
  return abstractMonsterFamilyData
end

local traitDisabledInRandomizerList = require("classes.lists.traitDisabledInRandomizerList")
local randomizedTraitChanceObjectsByFamilyUID = {}

function t:populateRandomizedTraitChanceObjects()
  randomizedTraitChanceObjectsByFamilyUID = {}
  if playerSettings:getDifficultyObject():shouldRandomizeTraits() then
    table.forEachSorted(monsterFamilyDataList, function(monsterFamilyUID, monsterFamilyData)
      if monsterFamilyData:isCatchable() then
        local traitUIDs = array.sort(table.filterToKeys(traitList, function(k, v)
          return not traitDisabledInRandomizerList[k]
        end))
        randomizedTraitChanceObjectsByFamilyUID[monsterFamilyUID] = array.map(monsterFamilyData:getTraitChanceObjects(), function(_traitChanceObject)
          return {
            _traitChanceObject[1],
            array.removeRandom(traitUIDs)
          }
        end)
      end
    end)
  end
end

function t:getRandomizedTraitChanceObjectsByFamilyUID()
  return randomizedTraitChanceObjectsByFamilyUID
end

local randomizedPrimaryTypeByFamilyUID = {}
local randomizedSecondaryTypeByFamilyUID = {}

function t:populateRandomizedTypes()
  randomizedPrimaryTypeByFamilyUID = {}
  randomizedSecondaryTypeByFamilyUID = {}
  local randomizeTypesMode = RandomizeTypesMode[playerSettings:getDifficultyObject():getRandomizeTypesMode()]
  if not randomizeTypesMode:isDisabled() and not randomizeTypesMode:shouldReplacePerMonster() then
    local typeValues = array.map(Type.valuesForMonsters, function(_typeValueObject)
      return _typeValueObject:getValue()
    end)
    if randomizeTypesMode:shouldReplacePerMonsterFamily() then
      table.forEachSorted(monsterFamilyDataList, function(monsterFamilyUID, monsterFamilyData)
        if not monsterFamilyData:hasType("crimsonite") then
          randomizedPrimaryTypeByFamilyUID[monsterFamilyUID] = array.random(typeValues)
          randomizedSecondaryTypeByFamilyUID[monsterFamilyUID] = array.random(typeValues)
        end
      end)
    elseif randomizeTypesMode:shouldShuffle() then
      local randomizedTypeByType = array.toRandomizationTable(typeValues)
      table.forEachSorted(monsterFamilyDataList, function(monsterFamilyUID, monsterFamilyData)
        if not monsterFamilyData:hasType("crimsonite") then
          randomizedPrimaryTypeByFamilyUID[monsterFamilyUID] = randomizedTypeByType[monsterFamilyData:getPrimaryType()]
          randomizedSecondaryTypeByFamilyUID[monsterFamilyUID] = randomizedTypeByType[monsterFamilyData:getSecondaryType()]
        end
      end)
    end
  end
end

local randomizedSkillObjectsByUID = {}

function t:getRandomizedSkillObjectsByUID()
  return randomizedSkillObjectsByUID
end

function t:populateRandomizedSkillObjects()
  randomizedSkillObjectsByUID = {}
  local randomizeSkillsMode = RandomizeSkillsMode[playerSettings:getDifficultyObject():getRandomizeSkillsMode()]
  if not randomizeSkillsMode:isDisabled() then
    table.forEachSorted(monsterFamilyDataList, function(monsterFamilyUID, monsterFamilyData)
      if monsterFamilyData:isCatchable() then
        local skills = table.filterToValuesSortedByKey(skillDataList, function(k, v)
          return not v:isDisabledInRandomizer()
        end)
        local skillObjects = table.deepclone(monsterFamilyData:getSkillObjects())
        local skillObjectSkills = array.map(skillObjects, function(_skillObject)
          return skillDataList[_skillObject.name]
        end)
        array.forEach(skillObjects, function(_skillObject, i)
          local skillsToChooseFrom = randomizeSkillsMode:isShuffle() and skillObjectSkills or skills
          local filteredSkillsToChooseFrom = skillsToChooseFrom
          local isFirstSkill = i == 1
          if isFirstSkill then
            filteredSkillsToChooseFrom = array.filter(filteredSkillsToChooseFrom, function(_skill)
              return _skill:getPower()
            end)
          end
          local shouldLimitToType = randomizeSkillsMode:isReplaceWithAnyButPreferSameType() and math.chance(40)
          if shouldLimitToType then
            local filteredSkillsWithSameType = array.filter(filteredSkillsToChooseFrom, function(_skill)
              return _skill:getType() == skillDataList[_skillObject.name]:getType()
            end)
            if 0 < #filteredSkillsWithSameType then
              filteredSkillsToChooseFrom = filteredSkillsWithSameType
            end
          end
          local newSkill = array.random(filteredSkillsToChooseFrom)
          array.remove(skillsToChooseFrom, newSkill)
          _skillObject.name = newSkill:getUID()
        end)
        local skillsWithPower = array.map(skillObjects, function(_skillObject)
          return skillDataList[_skillObject.name]:getPower() and skillDataList[_skillObject.name]
        end)
        local skillsWithPowerSortedByEnergyCost = array.sortDecreasing(skillsWithPower, function(_skill)
          return _skill:getEnergyCost() or 0
        end)
        array.forEach(skillObjects, function(_skillObject, i)
          if skillDataList[_skillObject.name]:getPower() then
            local skillWithLowestEnergyCostStillInList = array.remove(skillsWithPowerSortedByEnergyCost)
            _skillObject.name = skillWithLowestEnergyCostStillInList:getUID()
          end
        end)
        randomizedSkillObjectsByUID[monsterFamilyUID] = skillObjects
      end
    end)
  end
end

function abstractMonsterFamilyDataMeta:getMonsterFamilyAncestorData()
  return monsterFamilyAncestorDataList[self:getMonsterFamilyAncestorUID()]
end

function abstractMonsterFamilyDataMeta:isTitan()
  return string.starts(self:getUID(), "TITAN_")
end

function abstractMonsterFamilyDataMeta:isFusebox()
  return self:getUID() == "FUSEBOX"
end

function abstractMonsterFamilyDataMeta:isSpinnerBird()
  return self:getUID() == "NORMAL_SPINNER"
end

function abstractMonsterFamilyDataMeta:isCatchable()
  if self:isTitan() or self:isFusebox() or self:isSpinnerBird() then
    return false
  end
  if device:hasToUnlockFullGame() and not array.contains(DemoHelper:getDemoMonsterFamilies(), self:getUID()) then
    return false
  end
  if self:getMascotOf() ~= nil then
    return false
  end
  return true
end

function abstractMonsterFamilyDataMeta:isCatchableInCoromonRoguePlanet()
  if self:getMascotOf() ~= nil then
    return true
  end
  return self:isCatchable()
end

function abstractMonsterFamilyDataMeta:getRandomizablePrimaryType()
  return randomizedPrimaryTypeByFamilyUID[self:getUID()] or self:getPrimaryType()
end

function abstractMonsterFamilyDataMeta:getRandomizableSecondaryType()
  return randomizedSecondaryTypeByFamilyUID[self:getUID()] or self:getSecondaryType()
end

function abstractMonsterFamilyDataMeta:hasType(_type)
  if not app:usesDualTyping() then
    return self:getPrimaryType() == _type
  else
    return self:getPrimaryType() == _type or self:getSecondaryType() == _type
  end
end

function abstractMonsterFamilyDataMeta:hasRandomizableType(_type)
  if not app:usesDualTyping() then
    return self:getRandomizablePrimaryType() == _type
  else
    return self:getRandomizablePrimaryType() == _type or self:getRandomizableSecondaryType() == _type
  end
end

local function getRandomizableSkillObjects(_familyData, _shouldExcludeCrimsoniteSkills)
  local randomizableSkillObjects = randomizedSkillObjectsByUID[_familyData:getUID()] or _familyData:getSkillObjects()
  if _shouldExcludeCrimsoniteSkills then
    randomizableSkillObjects = array.filter(randomizableSkillObjects, function(_skillObject)
      return not _skillObject.onlyWhenCrimsonite
    end)
  end
  return randomizableSkillObjects
end

function abstractMonsterFamilyDataMeta:getRandomizableSkillObjects(_shouldExcludeCrimsoniteSkills)
  return array.copy(getRandomizableSkillObjects(self, _shouldExcludeCrimsoniteSkills))
end

function abstractMonsterFamilyDataMeta:getRandomizableSkillUIDs(_shouldExcludeCrimsoniteSkills)
  return array.map(self:getRandomizableSkillObjects(_shouldExcludeCrimsoniteSkills), function(_skillObject)
    return _skillObject.name
  end)
end

function abstractMonsterFamilyDataMeta:getRandomizableSkillObjectsForLevel(_level, _shouldExcludeCrimsoniteSkills)
  return array.filter(getRandomizableSkillObjects(self, _shouldExcludeCrimsoniteSkills), function(_skillObject)
    return _level >= _skillObject.unlockedAt
  end)
end

function abstractMonsterFamilyDataMeta:getRandomizableSkillUIDsForLevel(_level, _shouldExcludeCrimsoniteSkills)
  return array.map(self:getRandomizableSkillObjectsForLevel(_level, _shouldExcludeCrimsoniteSkills), function(_skillObject)
    return _skillObject.name
  end)
end

local levelUpArrayByRarity = {
  common = {
    7,
    24,
    58,
    113,
    194,
    309,
    461,
    656,
    900,
    1198,
    1555,
    1977,
    2470,
    3038,
    3686,
    4422,
    5249,
    6173,
    7200,
    8335,
    9583,
    10950,
    12442,
    14063,
    15818,
    17715,
    19757,
    21950,
    24300,
    26812,
    29491,
    32343,
    35374,
    38588,
    41990,
    45588,
    49385,
    53387,
    57600,
    62029,
    66679,
    71556,
    76666,
    82013,
    87602,
    93441,
    99533,
    105884,
    112500,
    119386,
    126547,
    133989,
    141718,
    149738,
    158054,
    166674,
    175601,
    184841,
    194400,
    204283,
    214495,
    225042,
    235930,
    247163,
    258746,
    270687,
    282989,
    295658,
    308700,
    322120,
    335923,
    350115,
    364702,
    379688,
    395078,
    410880,
    427097,
    443735,
    460800,
    478297,
    496231,
    514608,
    533434,
    552713,
    572450,
    592653,
    613325,
    634472,
    656100,
    678214,
    700819,
    723921,
    747526,
    771638,
    796262,
    821406,
    847073,
    873269
  },
  uncommon = {
    8,
    27,
    64,
    125,
    216,
    343,
    512,
    729,
    1000,
    1331,
    1728,
    2197,
    2744,
    3375,
    4096,
    4913,
    5832,
    6859,
    8000,
    9261,
    10648,
    12167,
    13824,
    15625,
    17576,
    19683,
    21952,
    24389,
    27000,
    29791,
    32768,
    35937,
    39304,
    42875,
    46656,
    50653,
    54872,
    59319,
    64000,
    68921,
    74088,
    79507,
    85184,
    91125,
    97336,
    103823,
    110592,
    117649,
    125000,
    132651,
    140608,
    148877,
    157464,
    166375,
    175616,
    185193,
    195112,
    205379,
    216000,
    226981,
    238328,
    250047,
    262144,
    274625,
    287496,
    300763,
    314432,
    328509,
    343000,
    357911,
    373248,
    389017,
    405224,
    421875,
    438976,
    456533,
    474552,
    493039,
    512000,
    531441,
    551368,
    571787,
    592704,
    614125,
    636056,
    658503,
    681472,
    704969,
    729000,
    753571,
    778688,
    804357,
    830584,
    857375,
    884736,
    912673,
    941192,
    970299
  },
  rare = {
    9,
    30,
    70,
    138,
    238,
    377,
    563,
    802,
    1100,
    1464,
    1901,
    2417,
    3018,
    3713,
    4506,
    5404,
    6415,
    7545,
    8800,
    10187,
    11713,
    13384,
    15206,
    17188,
    19334,
    21651,
    24147,
    26828,
    29700,
    32770,
    36045,
    39531,
    43234,
    47163,
    51322,
    55718,
    60359,
    65251,
    70400,
    75813,
    81497,
    87458,
    93702,
    100238,
    107070,
    114205,
    121651,
    129414,
    137500,
    145916,
    154669,
    163765,
    173210,
    183013,
    193178,
    203712,
    214623,
    225917,
    237600,
    249679,
    262161,
    275052,
    288358,
    302088,
    316246,
    330839,
    345875,
    361360,
    377300,
    393702,
    410573,
    427919,
    445746,
    464063,
    482874,
    502186,
    522007,
    542343,
    563200,
    584585,
    606505,
    628966,
    651974,
    675538,
    699662,
    724353,
    749619,
    775466,
    801900,
    828928,
    856557,
    884793,
    913642,
    943113,
    973210,
    1003940,
    1035311,
    1067329
  },
  legendary = {
    10,
    32,
    77,
    150,
    259,
    412,
    614,
    875,
    1200,
    1597,
    2074,
    2636,
    3293,
    4050,
    4915,
    5896,
    6998,
    8231,
    9600,
    11113,
    12778,
    14600,
    16589,
    18750,
    21091,
    23620,
    26342,
    29267,
    32400,
    35749,
    39322,
    43124,
    47165,
    51450,
    55987,
    60784,
    65846,
    71183,
    76800,
    82705,
    88906,
    95408,
    102221,
    109350,
    116803,
    124588,
    132710,
    141179,
    150000,
    159181,
    168730,
    178652,
    188957,
    199650,
    210739,
    222232,
    234134,
    246455,
    259200,
    272377,
    285994,
    300056,
    314573,
    329550,
    344995,
    360916,
    377318,
    394211,
    411600,
    429493,
    447898,
    466820,
    486269,
    506250,
    526771,
    547840,
    569462,
    591647,
    614400,
    637729,
    661642,
    686144,
    711245,
    736950,
    763267,
    790204,
    817766,
    845963,
    874800,
    904285,
    934426,
    965228,
    996701,
    1028850,
    1061683,
    1095208,
    1129430,
    1164359
  }
}

function abstractMonsterFamilyDataMeta:getLevelUpArray()
  return levelUpArrayByRarity[self:getRarity()]
end

function abstractMonsterFamilyDataMeta:getLevelForXp(_xp)
  return 1 + (array.findIndexByFunctionReversed(self:getLevelUpArray(), function(_xpRequiredForLevel)
    return _xpRequiredForLevel <= _xp
  end) or 0)
end

function abstractMonsterFamilyDataMeta:getXpForLevel(_level)
  return _level == 1 and 0 or self:getLevelUpArray()[_level - 1]
end

function abstractMonsterFamilyDataMeta:resolveRandomizableTraitChanceObjects()
  local traitChanceObjects = randomizedTraitChanceObjectsByFamilyUID[self:getUID()] or self:getTraitChanceObjects()
  traitChanceObjects = array.filter(traitChanceObjects, function(_obj)
    return _obj[1] > 0
  end)
  if #traitChanceObjects == 0 then
    traitChanceObjects = {
      {100, "ROBBER"}
    }
  end
  return traitChanceObjects
end

function abstractMonsterFamilyDataMeta:rollTraitUID()
  return array.rollFromTotal(self:resolveRandomizableTraitChanceObjects(), function(_obj)
    return _obj[1]
  end)[2]
end

function abstractMonsterFamilyDataMeta:rerollTraitUID(_originalTraitUID)
  local traitChancesWithoutOriginalTrait = array.filter(self:resolveRandomizableTraitChanceObjects(), function(_obj)
    return _obj[2] ~= _originalTraitUID
  end)
  return array.rollFromTotal(traitChancesWithoutOriginalTrait, function(_obj)
    return _obj[1]
  end)[2]
end

function abstractMonsterFamilyDataMeta:getRandomizableTraitUIDs()
  return array.map(self:resolveRandomizableTraitChanceObjects(), function(_obj)
    return _obj[2]
  end)
end

return t
