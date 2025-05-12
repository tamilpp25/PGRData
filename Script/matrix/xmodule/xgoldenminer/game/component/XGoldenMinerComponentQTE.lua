---@class XGoldenMinerComponentQTE:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityStone
local XGoldenMinerComponentQTE = XClass(XEntity, "XGoldenMinerComponentQTE")

--region Override
function XGoldenMinerComponentQTE:OnInit()
    self.Status = XEnumConst.GOLDEN_MINER.GAME_QTE_STATUS.NONE
    
    self.QTEGroupId = 0
    self.Time = 0
    self.CurTime = 0
    self.ClickCount = 0
    self.CurClickCount = 0
    self.WaitTime = 0
    
    ---@type UnityEngine.UI.RawImage
    self.QTEIcon = false
    ---@type UnityEngine.Transform
    self.AnimClick = false
    self.IsCanAnimClick = true
    ---@type UnityEngine.Transform
    self.ProgressPanel = false
    ---@type UnityEngine.UI.Image
    self.ProgressFillImage = false
    
    self.SpeedRate = 1
    self.AddScore = 0
    self.AddItemId = 0
    self.AddBuff = 0
end

function XGoldenMinerComponentQTE:OnRelease()
    self.QTEIcon = nil
    self.AnimClick = nil
    self.ProgressPanel = nil
    self.ProgressFillImage = nil
end
--endregion

--region Setter
function XGoldenMinerComponentQTE:InitQTEComponent(transform, clickCount, icon)
    self.CurTime = self.Time
    self.ClickCount = clickCount
    self.CurClickCount = 0
    self.QTEIcon = XUiHelper.TryGetComponent(transform, "Show", "RawImage")
    self.AnimClick = XUiHelper.TryGetComponent(transform, "AnimClick")

    if transform.anchoredPosition.x > CS.UnityEngine.Screen.width / 2 then
        self.ProgressPanel = XUiHelper.TryGetComponent(transform, "Panel01")
    else
        self.ProgressPanel = XUiHelper.TryGetComponent(transform, "Panel02")
    end
    if self.ProgressPanel then
        self.ProgressFillImage = XUiHelper.TryGetComponent(self.ProgressPanel, "ImgUiGoldenMinerJD01", "Image")
        self.ProgressPanel.gameObject:SetActiveEx(false)
    end
    self.QTEIcon:SetRawImage(icon)
end
--endregion

return XGoldenMinerComponentQTE