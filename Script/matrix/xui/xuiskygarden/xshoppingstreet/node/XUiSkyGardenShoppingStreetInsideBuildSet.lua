---@class XUiSkyGardenShoppingStreetInsideBuildSet : XUiNode
---@field ImgIcon UnityEngine.UI.Image
---@field TxtTitle UnityEngine.UI.Text
---@field BtnMinus XUiComponent.XUiButton
---@field TxtName UnityEngine.UI.Text
---@field BtnAdd XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetInsideBuildSet = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildSet")

--region 生命周期
function XUiSkyGardenShoppingStreetInsideBuildSet:OnStart(...)
    self:_RegisterButtonClicks()
end
--endregion

function XUiSkyGardenShoppingStreetInsideBuildSet:SetTilte(title)
    self.TxtTitle.text = title
end

function XUiSkyGardenShoppingStreetInsideBuildSet:SetName(name)
    self.TxtName.text = name
end

function XUiSkyGardenShoppingStreetInsideBuildSet:SetIcon(icon)
    self.ImgIcon:SetRawImage(icon)
end

function XUiSkyGardenShoppingStreetInsideBuildSet:SetUpdateCallback(cb)
    self._updateCb = cb
end

function XUiSkyGardenShoppingStreetInsideBuildSet:UpdateData(index)
    if self._updateCb then self._updateCb(index) end
end

function XUiSkyGardenShoppingStreetInsideBuildSet:SetAddCb(cb)
    self._addCb = cb
end

function XUiSkyGardenShoppingStreetInsideBuildSet:SetMinusCb(cb)
    self._minCb = cb
end

function XUiSkyGardenShoppingStreetInsideBuildSet:SetIndex(index, minNum, maxNum, isLoop)
    self._Index = index
    self._MinNum = minNum
    self._MaxNum = maxNum
    self._IsLoop = isLoop
    self:UpdateData(self._Index)
end

--region 按钮事件
function XUiSkyGardenShoppingStreetInsideBuildSet:OnBtnMinusClick()
    local nextIndex = self._Index - 1
    if self._IsLoop then
        if nextIndex < self._MinNum then
            nextIndex = self._MaxNum
        end
    else
        nextIndex = XMath.Clamp(nextIndex, self._MinNum, self._MaxNum)
    end
    if nextIndex == self._Index then return end

    self._Index = nextIndex
    if self._addCb then
        self._addCb(self._Index)
    else
        self:UpdateData(self._Index)
    end
end

function XUiSkyGardenShoppingStreetInsideBuildSet:OnBtnAddClick()
    local nextIndex = self._Index + 1
    if self._IsLoop then
        if nextIndex > self._MaxNum then
            nextIndex = self._MinNum
        end
    else
        nextIndex = XMath.Clamp(nextIndex, self._MinNum, self._MaxNum)
    end
    if nextIndex == self._Index then return end

    self._Index = nextIndex
    if self._minCb then
        self._minCb(self._Index)
    else
        self:UpdateData(self._Index)
    end
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetInsideBuildSet:_RegisterButtonClicks()
    --在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnMinus, self.OnBtnMinusClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnBtnAddClick, true)
end
--endregion

return XUiSkyGardenShoppingStreetInsideBuildSet
