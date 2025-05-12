
---@class XUiSGGridQualityLimit : XUiNode
---@field _Control XSkyGardenCafeControl
---@field Parent XUiSkyGardenCafeHandBook
local XUiSGGridQualityLimit = XClass(XUiNode, "XUiSGGridQualityLimit")

function XUiSGGridQualityLimit:OnStart()
    self:InitUi()
    self:InitCb()
end

function XUiSGGridQualityLimit:Refresh(quality, capacity, count)
    --region 刷新可能会比较频繁，不想做字符串拼接
    if self.ImgQuality1 then
        self.ImgQuality1.gameObject:SetActiveEx(quality == 1)
    end
    if self.ImgQuality2 then
        self.ImgQuality2.gameObject:SetActiveEx(quality == 2)
    end
    if self.ImgQuality3 then
        self.ImgQuality3.gameObject:SetActiveEx(quality == 3)
    end
    if self.ImgQuality4 then
        self.ImgQuality4.gameObject:SetActiveEx(quality == 4)
    end
    if self.ImgQuality5 then
        self.ImgQuality5.gameObject:SetActiveEx(quality == 5)
    end
    --endregion
    self.TxtNum.text = string.format("%d/%d", count, capacity)
end

function XUiSGGridQualityLimit:InitUi()
end

function XUiSGGridQualityLimit:InitCb()
end

return XUiSGGridQualityLimit