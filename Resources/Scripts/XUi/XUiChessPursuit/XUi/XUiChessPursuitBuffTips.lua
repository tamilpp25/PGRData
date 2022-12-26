local XUiChessPursuitBuffTips = XLuaUiManager.Register(XLuaUi, "UiChessPursuitBuffTips")
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local XUiChessPursuitBuffTipsGrid = require("XUi/XUiChessPursuit/XUi/XUiChessPursuitBuffTipsGrid")

function XUiChessPursuitBuffTips:OnAwake()
    self:AutoAddListener()
end

function XUiChessPursuitBuffTips:OnStart(mapId, targetType, cubeIndex)
    self.MapId = mapId
    self.TargetType = targetType
    self.CubeIndex = cubeIndex
    self:UpdateInfo()
end

--@region 点击事件

function XUiChessPursuitBuffTips:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiChessPursuitBuffTips:OnBtnCloseClick()
    self:Close()
end

--@endregion

function XUiChessPursuitBuffTips:UpdateInfo()
    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)
    if self.TargetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS then
        local xChessPursuitCardDbList = chessPursuitMapDb:GetBossCardDb()

        if next(xChessPursuitCardDbList) then
            self:RefresGrid(xChessPursuitCardDbList)
        end
    elseif self.TargetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE then
        local xChessPursuitMapGridCardDb = chessPursuitMapDb:GetGridCardDb()

        for _,v in ipairs(xChessPursuitMapGridCardDb) do
            if v.Id == self.CubeIndex-1 then
                local xChessPursuitCardDbList = v.Cards
                if next(xChessPursuitCardDbList) then
                    self:RefresGrid(xChessPursuitCardDbList)
                end
                break
            end
        end
    end
end

function XUiChessPursuitBuffTips:RefresGrid(xChessPursuitCardDbList)
    self.GridBuff.gameObject:SetActiveEx(false)

    for _,card in ipairs(xChessPursuitCardDbList) do
        local grid = CSUnityEngineObjectInstantiate(self.GridBuff, self.PanelContent.transform)
        grid.gameObject:SetActiveEx(true)
        local uiChessPursuitBuffTipsGrid = XUiChessPursuitBuffTipsGrid.New(grid, self, card)
        uiChessPursuitBuffTipsGrid:Refresh()
    end
end
