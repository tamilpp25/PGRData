local XUiChessPursuitPanelFightStage = XClass(nil, "XUiChessPursuitPanelFightStage")
local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiChessPursuitPanelFightStage:Ctor(ui, uiRoot, mapId)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.MapId = mapId

    XTool.InitUiObject(self)
end

function XUiChessPursuitPanelFightStage:Refresh()
    local mapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)
    local config = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)
    local mapBoss = XDataCenter.ChessPursuitManager.GetChessPursuitMapBoss(config.BossId)

    if mapDb:IsClear() then
        self.PanelEnd.gameObject:SetActiveEx(true)
        self.PanelJd.gameObject:SetActiveEx(false)

        self.TxtNumber.text = mapDb:GetBossBattleCount()
    else
        self.PanelJd.gameObject:SetActiveEx(true)
        self.PanelEnd.gameObject:SetActiveEx(false)

        local ration = mapDb:GetBossHp() / mapBoss:GetInitHp()
        local bloodVolume = ration * 100
        if bloodVolume > 0 and bloodVolume < 0.01 then
            bloodVolume = 0.01
        end
        
        self.ImgJd.fillAmount = ration
        self.TxtJd.text = CSXTextManagerGetText("ChessPursuitBloodCount", string.format("%.2f", bloodVolume))
    end
end

return XUiChessPursuitPanelFightStage