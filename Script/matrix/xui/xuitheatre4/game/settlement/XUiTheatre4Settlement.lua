local XUiPanelTheatre4SettlementPageOne = require("XUi/XUiTheatre4/Game/Settlement/XUiPanelTheatre4SettlementPageOne")
local XUiPanelTheatre4SettlementPageTwo = require("XUi/XUiTheatre4/Game/Settlement/XUiPanelTheatre4SettlementPageTwo")
---@class XUiTheatre4Settlement : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4Settlement = XLuaUiManager.Register(XLuaUi, "UiTheatre4Settlement")

function XUiTheatre4Settlement:OnAwake()
    self.PanelPage1.gameObject:SetActiveEx(false)
    self.PanelPage2.gameObject:SetActiveEx(false)
end

---@param endingId number 结局Id
function XUiTheatre4Settlement:OnStart(endingId)
    self.EndingId = endingId
end

function XUiTheatre4Settlement:OnEnable()
    self:RefreshEndingInfo()
    self:ShowPageOne()
end

function XUiTheatre4Settlement:OnDestroy()
    self._Control:ClearAdventureSettleData()
    self._Control:ClearCameraFollowLastPos()
end

function XUiTheatre4Settlement:RefreshEndingInfo()
    local endingConfig = self._Control:GetEndingConfig(self.EndingId)
    -- 图标
    if not string.IsNilOrEmpty(endingConfig.IconBg) then
        self.RImgIcon:SetRawImage(endingConfig.IconBg)
    end
    if self.ImgIconBg then
        if string.IsNilOrEmpty(endingConfig.Icon) then
            self.ImgIconBg.gameObject:SetActiveEx(false)
        else
            self.ImgIconBg.gameObject:SetActiveEx(true)
            self.ImgIconBg:SetRawImage(endingConfig.Icon)
        end
    end
    -- 名称
    self.TxtName.text = endingConfig.Name
end

-- 显示结算页面1
function XUiTheatre4Settlement:ShowPageOne(isPlayMoveBack)
    if not self.PageOne then
        ---@type XUiPanelTheatre4SettlementPageOne
        self.PageOne = XUiPanelTheatre4SettlementPageOne.New(self.PanelPage1, self)
    end
    self.PageOne:Open()
    self.PageOne:Refresh(isPlayMoveBack)
end

-- 显示结算页面2
function XUiTheatre4Settlement:ShowPageTwo()
    if not self.PageTwo then
        ---@type XUiPanelTheatre4SettlementPageTwo
        self.PageTwo = XUiPanelTheatre4SettlementPageTwo.New(self.PanelPage2, self)
    end
    self.PageTwo:Open()
    self.PageTwo:Refresh()
end

return XUiTheatre4Settlement
