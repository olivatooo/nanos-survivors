Events.Subscribe("UpdateXP", function (current_xp, max_xp) {
  document.getElementById("xp-fill").style.width = `${Math.round((current_xp / max_xp) * 100)}%`;
});

Events.Subscribe("UpdateLevel", function (level) {
  document.getElementById("level").innerHTML = `Level ${level}`;
});

function ShowSkillList() {
  var level_up_options = document.getElementById("level-up");
  level_up_options.classList.remove("hidden");
}

function HideSkillList() {
  var level_up_options = document.getElementById("level-up");
  level_up_options.classList.add("hidden");
}

Events.Subscribe("LevelUpSkills", function (skills) {
  ShowSkillList();
  let skill_list = JSON.parse(skills);
  for (let i = 0; i < skill_list.length; i++) {
    // Iterate all skills and show
    let skill_title = skill_list[i].Title;
    let description = skill_list[i].Description;
    let skill_icon = skill_list[i].Icon;

    document.getElementById("skill_name_" + i).innerHTML = skill_title;
    document.getElementById("skill_desc_" + i).innerHTML = description;
    document.getElementById("skill_icon_" + i).src = "Images/icons/" + skill_icon + ".png";
  }
});

Events.Subscribe("SelectedSkill", function () {
  HideSkillList();
});
