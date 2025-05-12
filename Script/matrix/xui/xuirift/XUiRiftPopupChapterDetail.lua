local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiRiftPopupChapterDetail : XLuaUi 章节掉落详情弹框
---@field _Control XRiftControl
local XUiRiftPopupChapterDetail = XLuaUiManager.Register(XLuaUi, "UiRiftPopupChapterDetail")

function XUiRiftPopupChapterDetail:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
    self:RegisterClickEvent(self.BtnCloseTip, self.ClosePluginTip)
end

---@param chapter XRiftChapter
function XUiRiftPopupChapterDetail:OnStart(chapter)
    self._Chapter = chapter

    local endTimeSecond = self._Control:GetTime()
    self:SetAutoCloseInfo(endTimeSecond, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    ---@type XUiGridRiftPluginDrop
    self._Tip = require("XUi/XUiRift/Grid/XUiGridRiftPluginDrop").New(self.GridRiftPluginTips, self)
    self._Param = {}
    self._Param.DecomposeCount = 0

    local config = chapter:GetConfig()
    self:SetUiSprite(self.ImgBuff, config.BuffIcon)
    self.TxtBuff.text = config.BuffName
    self.TxtBuffDesc.text = config.BuffDesc
    self.TxtTitle.text = config.Name
    self.TxtTitle2.text = config.DropDesc

    self.DynamicTable = XDynamicTableNormal.New(self.ListPlugin)
    self.DynamicTable:SetProxy(require("XUi/XUiRift/Grid/XUiGridRiftShowPlugin"), self)
    self.DynamicTable:SetDelegate(self)

    self._Datas = self._Control:GetChapterPluginShow(chapter:GetChapterId())
    self.DynamicTable:SetDataSource(self._Datas)
    self.DynamicTable:ReloadDataSync()
    self.GridRiftPlugin.gameObject:SetActiveEx(false)

    self._Tip:Close()
end

---@param grid XUiGridRiftShowPlugin
function XUiRiftPopupChapterDetail:OnDynamicTableEvent(event, index, grid)
    if not grid then
        return
    end
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._Datas[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OpenPluginTip(index, grid.Transform)
    end
end

-- 注意GridRiftPluginTips的锚点
function XUiRiftPopupChapterDetail:OpenPluginTip(index, grid)
    self._Tip:Open()
    self._Param.PluginId = self._Datas[index]
    self._Tip:Refresh(self._Param)
    local pos = self.GridRiftPluginTips.parent:InverseTransformPoint(grid.transform.position)
    local posX = pos.x - grid.rect.width * grid.localScale.x * grid.pivot.x
    local posY = pos.y + grid.rect.height * grid.localScale.y * (1 - grid.pivot.y)
    posY = math.max(posY, self.GridRiftPluginTips.rect.height - self.Transform.rect.height / 2)
    self.GridRiftPluginTips.pivot.x = posX + self.GridRiftPluginTips.rect.width > self.Transform.rect.width / 2 and 1 or 0
    self.GridRiftPluginTips.localPosition = Vector3(posX, posY, 0)
    self.TipAnimEnable.gameObject:PlayTimelineAnimation()
end

function XUiRiftPopupChapterDetail:ClosePluginTip()
    if self._Tip:IsNodeShow() then
        self._Tip:Close()
    else
        self:Close()
    end
end

function XUiRiftPopupChapterDetail:OnBtnEnterClick()
    if self._Control:IsCurrPlayingChapter(self._Chapter:GetChapterId()) then
        self:OpenFightLayerSelect()
    else
        self._Control:RequestRiftStartChapter(self._Chapter:GetChapterId(), handler(self, self.OpenFightLayerSelect))
    end
end

function XUiRiftPopupChapterDetail:OpenFightLayerSelect()
    XLuaUiManager.PopThenOpen("UiRiftFightLayerSelect", self._Chapter:GetChapterId())
end

return XUiRiftPopupChapterDetail