Package.Require("Skills.lua")

Sky.Spawn()
-- World.SetSunSpeed(0)
-- World.SetTime(0, 0)

-- World.SetFogDensity(1, 0)
-- World.SetSkyLightIntensity(0.1)
-- World.SetPPChromaticAberration(1, 0)
-- World.SetPPGlobalSaturation(Color.WHITE * 0.9)
-- World.SetPPImageEffects(0.5)
Sky.Spawn()
Sky.SetFog(1000)
Sky.SetTimeOfDay(3, 33)
Sky.SetAnimateTimeOfDay(false)


UI = WebUI("nano-survivors", "file://UI/index.html")
LevelUp = 0

Music = Sound(Vector(), "package://nano-survivors/Client/Musics/ice-demon.ogg", true, false, SoundType.Music, 1, 1, 400,
  3600, AttenuationFunction.Linear, false, SoundLoopMode.Forever)


Events.Subscribe("SpawnSound", function(location, sound_asset, is_2D, volume, pitch)
  Sound(location or Vector(), sound_asset, is_2D, true, SoundType.SFX, volume or 1, pitch or 1)
end)

Events.Subscribe("UpdateXP", function(current_xp, max_xp)
  UI:CallEvent("UpdateXP", current_xp, max_xp)
end)

Events.Subscribe("UpdateLevel", function(level)
  LevelUp = LevelUp + 1
  UI:CallEvent("UpdateLevel", level)
  Package.Log("User can spent %s", LevelUp)
end)

Skills = {}
Events.Subscribe("LevelUpSkills", function(skills)
  -- TODO: Place here the logic to save skills for later usage
  Skills = skills
  Package.Log(JSON.stringify(skills))
  UI:CallEvent("LevelUpSkills", JSON.stringify(skills))
end)

UI:Subscribe("UpgradeSkill", function(id)
  if (LevelUp - 1) >= 0 then
    Package.Log("User wants skill %s", id)
    LevelUp = LevelUp - 1
    Events.CallRemote("UpgradeSkill", id)
  end
end)
Input.Register("LevelUp_1", "One")
Input.Register("LevelUp_2", "Two")
Input.Register("LevelUp_3", "Three")

function UpgradeSkill(id)
  if (LevelUp - 1) >= 0 then
    Skills = {}
    Package.Log("User wants skill %s", id)
    LevelUp = LevelUp - 1
    Events.CallRemote("UpgradeSkill", id)
  end
  if LevelUp == 0 then
    UI:CallEvent("SelectedSkill")
  end
end

Input.Bind("LevelUp_1", InputEvent.Released, function()
  if next(Skills) then
    local id = Skills[1].ID
    UpgradeSkill(id)
  end
end)

Input.Bind("LevelUp_2", InputEvent.Released, function()
  if next(Skills) then
    local id = Skills[2].ID
    UpgradeSkill(id)
  end
end)

Input.Bind("LevelUp_3", InputEvent.Released, function()
  if next(Skills) then
    local id = Skills[3].ID
    UpgradeSkill(id)
  end
end)
