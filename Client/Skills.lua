function AutoAim()
  Input.SetMouseEnabled(false)
  Input.SetMouseCursor(CursorType.SlashedCircle)
end
Events.Subscribe("AutoAim", AutoAim)
