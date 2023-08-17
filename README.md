# Nanos Survivors

Nanos World gamemode based in vampire survivors to add a new skill check Server/Skills.lua

Add New Skill example:

```lua
-- In Server/Skills.lua

-- Increases gun damage by 1
function MoreGunDamage(character)
  local weapon = character:GetPicked()
  weapon:SetDamage(weapon:GetDamage() + 1)
end

RegisterSkill("More Gun Damage", "Add more gun damage, simple!", "duel", MoreGunDamage)

-- NOTE:
-- You can see a list of skill icons in Client/UI/Images/icons
-- Just use the icon name without the .png
-- In this example we are using the "duel" icon
```

Simple! There are a lot of problems and gameplay issues, but hey, it's fun
