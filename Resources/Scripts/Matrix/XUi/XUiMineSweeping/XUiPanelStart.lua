local XUiPanelStart = XClass(nil, "XUiPanelStart")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiPanelStart:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiPanelStart:SetButtonCallBack()
    self.BtnStart.CallBack = function()
        self:OnBtnStartClick()
    end
end

function XUiPanelStart:OnBtnStartClick()
    local chapterEntity = XDataCenter.MineSweepingManager.GetChapterEntityByIndex(self.CurCharterIndex)
    local stageEntity = chapterEntity:GetCurStageEntity()
    local curCoinCount = XDataCenter.MineSweepingManager.GetMineSweepingCoinItemCount()
    
    if curCoinCount < stageEntity:GetCostCoinNum() and not chapterEntity:IsFailed() then
        XUiManager.TipText("MineSweepingNotCoinHint")
        return
    end
    XDataCenter.MineSweepingManager.MineSweepingStartStageRequest(chapterEntity:GetChapterId(), stageEntity:GetStageId())
end

function XUiPanelStart:UpdatePanel(curCharterIndex)
    self.CurCharterIndex = curCharterIndex
    if curCharterIndex then
        local chapterEntity = XDataCenter.MineSweepingManager.GetChapterEntityByIndex(curCharterIndex)
        local stageEntity = chapterEntity:GetCurStageEntity()
        local coinId = XDataCenter.MineSweepingManager.GetMineSweepingCoinItemId()
        local coinIcon = XDataCenter.ItemManager.GetItemIcon(coinId)
        self.TxtLevel.text = stageEntity:GetName()
        self.TxtCount.text = stageEntity:GetCostCoinNum()
        self.RawImage:SetRawImage(coinIcon)
        self.PanelExpend.gameObject:SetActiveEx(not chapterEntity:IsFailed() and not chapterEntity:IsSweeping())
    end
end

function XUiPanelStart:ShowPanel(IsShow)
    if IsShow then
        self.GameObject:SetActiveEx(true)
        self.Base:PlayAnimationWithMask("PanelStartEnable")
    else
        if self.Base:IsChapterIndexChange() then
            self.GameObject:SetActiveEx(false)
        else
            self.Base:PlayAnimationWithMask("PanelStartDisable",function ()
                    self.GameObject:SetActiveEx(false)
                end)
        end
        
    end
end
return XUiPanelStart