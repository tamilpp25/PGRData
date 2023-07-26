---@class XUiGridCerberusGameStage
local XUiGridCerberusGameStage = XClass(nil, "XUiGridCerberusGameStage")

function XUiGridCerberusGameStage:Ctor()
end

function XUiGridCerberusGameStage:InitData(ui, index, rootui)
    self.RootUi = rootui
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.GridIndex = index
    XTool.InitUiObject(self)
end

---@param xStoryPoint XCerberusGameStoryPoint
function XUiGridCerberusGameStage:Refresh(xStoryPoint, ui, index, rootui)
    self:InitData(ui, index, rootui)

    self.XStoryPoint = xStoryPoint
    self.Transform.parent.gameObject:SetActiveEx(xStoryPoint:GetIsShow())
    if not xStoryPoint:GetIsShow() then
        return
    end

    local stageId = nil
    local xStage = xStoryPoint:GetXStage()
    if xStage then
        stageId = xStage.StageId
        
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if self.TxtStageName then
            self.TxtStageName.text = stageCfg.Name
        end
    
        if self.TxtStage then
            self.TxtStage.text = "STAGE-"..self.GridIndex
        end

        -- 星星
        local starMap = xStage:GetStarsMapByMark()
        if self.PanelStars and xStage then
            local childCount = self.PanelStars.childCount
            for cSharpIndex = 0, childCount - 1 do
                local luaIndex = cSharpIndex + 1
                local starInfo = starMap[luaIndex]
                local starTrans = self.PanelStars:GetChild(cSharpIndex)
                if starTrans then
                    starTrans:Find("Img"..luaIndex).gameObject:SetActiveEx(starInfo)
                end
            end
        end
    end

    self.PanelLock.gameObject:SetActiveEx(not xStoryPoint:GetIsOpen())
    self.PanelComplete.gameObject:SetActiveEx(xStoryPoint:GetIsPassed())
end

function XUiGridCerberusGameStage:SetPanelSelect(value)
    self.PanelSelect.gameObject:SetActiveEx(value)
end

return XUiGridCerberusGameStage