--Loading界面
local XUiFubenRpgMakerGameMovie = XLuaUiManager.Register(XLuaUi, "UiFubenRpgMakerGameMovie")

function XUiFubenRpgMakerGameMovie:OnStart(stageId)
    if not XTool.IsNumberValid(stageId) then
        return
    end

    self.TxtTitle.text = XRpgMakerGameConfigs.GetRpgMakerGameStageName(stageId)

    local desc = XRpgMakerGameConfigs.GetRpgMakerGameStageHint(stageId)
    self.TxtContent.text = string.gsub(desc, "\\n", "\n")
end

function XUiFubenRpgMakerGameMovie:OnEnable()
    self:PlayAnimation("ThemeEnable")
end