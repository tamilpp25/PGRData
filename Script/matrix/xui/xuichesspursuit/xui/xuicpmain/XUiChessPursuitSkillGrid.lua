local XUiChessPursuitSkillGrid = XClass(nil, "XUiChessPursuitSkillGrid")
local CSUnityEngineVector3 = CS.UnityEngine.Vector3

function XUiChessPursuitSkillGrid:Ctor(ui, uiRoot, cubeIndex, mapId, targetType)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CubeIndex = cubeIndex
    self.MapId = mapId
    self.TargetType = targetType

    XTool.InitUiObject(self)

    self.Transform.localScale = CSUnityEngineVector3(5,5,5)
end

function XUiChessPursuitSkillGrid:Dispose()
    if self.GameObject then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
    end

    self.GameObject = nil
end

function XUiChessPursuitSkillGrid:SetActiveEx(isShow)
    self.GameObject:SetActiveEx(isShow)
end

function XUiChessPursuitSkillGrid:Refresh()
    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)
    if self.TargetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS then
        local xChessPursuitCardDbList = chessPursuitMapDb:GetBossCardDb()

        if next(xChessPursuitCardDbList) then
            self.GameObject:SetActiveEx(true)
            self:RefreshIcon(xChessPursuitCardDbList)
        else
            self.GameObject:SetActiveEx(false)
        end
    elseif self.TargetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE then
        local xChessPursuitMapGridCardDb = chessPursuitMapDb:GetGridCardDb()
        local isActive = false
        
        for _,v in ipairs(xChessPursuitMapGridCardDb) do
            if v.Id == self.CubeIndex-1 then
                local xChessPursuitCardDbList = v.Cards
                if next(xChessPursuitCardDbList) then
                    isActive = true
                    self:RefreshIcon(xChessPursuitCardDbList)
                end
                break
            end
        end

        self.GameObject:SetActiveEx(isActive)
    end
end

--更新来自临时数据的
function XUiChessPursuitSkillGrid:RefreshByTemp(cards)
    local index = 0
    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)
    if self.TargetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS then
        local xChessPursuitCardDbList = chessPursuitMapDb:GetBossCardDb()
        if next(xChessPursuitCardDbList) then
            index = #xChessPursuitCardDbList
        end
    elseif self.TargetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE then
        local xChessPursuitMapGridCardDb = chessPursuitMapDb:GetGridCardDb()
        for _,v in ipairs(xChessPursuitMapGridCardDb) do
            if v.Id == self.CubeIndex-1 then
                local xChessPursuitCardDbList = v.Cards
                if next(xChessPursuitCardDbList) then
                    index = #xChessPursuitCardDbList
                end
                break
            end
        end
    end
    
    if index == 0 and (not cards or not next(cards)) then
        self.GameObject:SetActiveEx(false)
    else
        self.GameObject:SetActiveEx(true)
    end

    local cardIndex = 1
    for i=index + 1,XChessPursuitCtrl.CARD_MAX_COUNT do
        if cards and cards[cardIndex] then
            self["Skill"..i].gameObject:SetActiveEx(true)
            local cardCfg = XChessPursuitConfig.GetChessPursuitCardTemplate(cards[cardIndex].CardCfgId)
            self["RawImageIcon" .. i]:SetRawImage(cardCfg.Icon)
            self["RawImageKuang" .. i]:SetRawImage(cardCfg.QualityIconSmall)
            cardIndex = cardIndex + 1
        else
            self["Skill"..i].gameObject:SetActiveEx(false)
        end
    end
end

function XUiChessPursuitSkillGrid:RefreshIcon(xChessPursuitCardDbList)
    for i=1,XChessPursuitCtrl.CARD_MAX_COUNT do
        local card = xChessPursuitCardDbList[i]
        if card then
            self["Skill"..i].gameObject:SetActiveEx(true)
            local cardCfg = XChessPursuitConfig.GetChessPursuitCardTemplate(card.CardCfgId)
            self["RawImageIcon" .. i]:SetRawImage(cardCfg.Icon)
            self["RawImageKuang" .. i]:SetRawImage(cardCfg.QualityIconSmall)
        else
            self["Skill"..i].gameObject:SetActiveEx(false)
        end
    end
end

function XUiChessPursuitSkillGrid:RefreshPos()
    if not self.GameObject.activeSelf then
        return
    end

    local ts
    local offzetY

    if self.TargetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS then
        ts = self.UiRoot.ChessPursuitBoss.Transform
        offzetY = -0.55
    elseif self.TargetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE then
        local chessPursuitCube = XChessPursuitCtrl.GetChessPursuitCubes()
        ts = chessPursuitCube[self.CubeIndex].Transform
        offzetY = 0.5
    end

    self.Transform.position = XChessPursuitCtrl.WorldToUIPosition(CSUnityEngineVector3(ts.position.x, ts.position.y + offzetY, ts.position.z))
end

return XUiChessPursuitSkillGrid