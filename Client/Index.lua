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
-- Sky.SetFog(1000)
Sky.SetTimeOfDay(3, 33)
Sky.SetAnimateTimeOfDay(false)


UI = WebUI("nanos-survivors", "file://UI/index.html")
LevelUp = 0

Music = Sound(Vector(), "package://nanos-survivors/Client/Musics/ice-demon.ogg", true, false, SoundType.Music, 1, 1, 400,
  3600, AttenuationFunction.Linear, false, SoundLoopMode.Forever)


Events.SubscribeRemote("SpawnSound", function(location, sound_asset, is_2D, volume, pitch)
  Sound(location or Vector(), sound_asset, is_2D, true, SoundType.SFX, volume or 1, pitch or 1)
end)

Events.SubscribeRemote("UpdateXP", function(current_xp, max_xp)
  UI:CallEvent("UpdateXP", current_xp, max_xp)
end)

Events.SubscribeRemote("UpdateLevel", function(level)
  LevelUp = LevelUp + 1
  UI:CallEvent("UpdateLevel", level)
  Console.Log("User can spent %s", LevelUp)
end)

Skills = {}
SkillQueue = {}
IsChoosingSkills = false

Events.SubscribeRemote("LevelUpSkills", function(skills)
  -- Add skills to queue if player is currently choosing
  if IsChoosingSkills then
    table.insert(SkillQueue, skills)
    return
  end
  
  -- Show skills UI and set choosing state
  IsChoosingSkills = true
  Skills = skills
  Console.Log(JSON.stringify(skills))
  UI:CallEvent("LevelUpSkills", JSON.stringify(skills))
end)

UI:Subscribe("UpgradeSkill", function(id)
  if (LevelUp - 1) >= 0 then
    Console.Log("User wants skill %s", id)
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
    Console.Log("User wants skill %s", id)
    LevelUp = LevelUp - 1
    Events.CallRemote("UpgradeSkill", id)
  end
  if LevelUp == 0 then
    UI:CallEvent("SelectedSkill")
  end
  
  -- Check if there are queued skills after selection
  IsChoosingSkills = false
  if #SkillQueue > 0 then
    local nextSkills = table.remove(SkillQueue, 1)
    IsChoosingSkills = true
    Skills = nextSkills
    UI:CallEvent("LevelUpSkills", JSON.stringify(nextSkills))
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

-- When LocalPlayer spawns, sets an event on it to trigger when we possesses a new character, to store the local controlled character locally. This event is only called once, see Package:Subscribe("Load") to load it when reloading a package
Client.Subscribe("SpawnLocalPlayer", function(local_player)
    local_player:Subscribe("Possess", function(player, character)
        UpdateLocalCharacter(character)
    end)
end)

-- When package loads, verify if LocalPlayer already exists (eg. when reloading the package), then try to get and store it's controlled character
Package.Subscribe("Load", function()
    local local_player = Client.GetLocalPlayer()
    if (local_player ~= nil) then
        UpdateLocalCharacter(local_player:GetControlledCharacter())
    end
end)

-- Function to set all needed events on local character (to update the UI when it takes damage or dies)
function UpdateLocalCharacter(character)
    -- Verifies if character is not nil (eg. when GetControllerCharacter() doesn't return a character)
    if (character == nil) then return end

    -- Updates the UI with the current character's health
    UpdateHealth(character:GetHealth())

    -- Sets on character an event to update the health's UI after it takes damage
    character:Subscribe("TakeDamage", function(charac, damage, type, bone, from_direction, instigator, causer)
        UpdateHealth(math.max(charac:GetHealth() - damage, 0))
    end)

    -- Sets on character an event to update the health's UI after it dies
    character:Subscribe("Death", function(charac)
        UpdateHealth(0)
    end)

    -- Try to get if the character is holding any weapon
    local current_picked_item = character:GetPicked()

    -- If so, update the UI
    if (current_picked_item and current_picked_item:GetClass().GetName() == "Weapon") then
        UpdateAmmo(true, current_picked_item:GetAmmoClip(), current_picked_item:GetAmmoBag())
    end

    -- Sets on character an event to update his grabbing weapon (to show ammo on UI)
    character:Subscribe("PickUp", function(charac, object)
        if (object:GetClass().GetName() == "Weapon") then
            UpdateAmmo(true, object:GetAmmoClip(), object:GetAmmoBag())
        end
    end)

    -- Sets on character an event to remove the ammo ui when he drops it's weapon
    character:Subscribe("Drop", function(charac, object)
        UpdateAmmo(false)
    end)

    -- Sets on character an event to update the UI when he fires
    character:Subscribe("Fire", function(charac, weapon)
        UpdateAmmo(true, weapon:GetAmmoClip(), weapon:GetAmmoBag())
    end)

    -- Sets on character an event to update the UI when he reloads the weapon
    character:Subscribe("Reload", function(charac, weapon, ammo_to_reload)
        UpdateAmmo(true, weapon:GetAmmoClip(), weapon:GetAmmoBag())
    end)
end

-- Function to update the Ammo's UI
function UpdateAmmo(enable_ui, ammo, ammo_bag)
    UI:CallEvent("UpdateWeaponAmmo", ammo, ammo_bag)
end

-- Function to update the Health's UI
function UpdateHealth(health)
    UI:CallEvent("UpdateHealth", health)
end

Timer.SetInterval(function()
    local players = {}
    for _, player in pairs(Player.GetAll()) do
        table.insert(players, {
            icon = player:GetAccountIconURL(),
            name = player:GetName()
        })
    end
    UI:CallEvent("UpdatePlayers", players)
end, 2000)


