local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiBigWorldBackpackItem : XUiNode
---@field Lock UnityEngine.RectTransform
---@field Red UnityEngine.RectTransform
---@field PanelEmpty UnityEngine.RectTransform
---@field PanelSelect UnityEngine.RectTransform
---@field ItemGrid UnityEngine.RectTransform
---@field Parent XUiBigWorldBackpack
local XUiBigWorldBackpackItem = XClass(XUiNode, "XUiBigWorldBackpackItem")

-- region 生命周期

function XUiBigWorldBackpackItem:OnStart()
    ---@type XUiGridBWItem
    self._Grid = false
    self._Index = 0
    self:_RegisterButtonClicks()
end

function XUiBigWorldBackpackItem:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldBackpackItem:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldBackpackItem:OnDestroy()

end

-- endregion

-- region 按钮事件

function XUiBigWorldBackpackItem:OnGridClick(itemParams, goodParams)
    self:SetSelect(true)
    self.Parent:OnItemGridClick(self._Index, itemParams, goodParams)
end

-- endregion

function XUiBigWorldBackpackItem:Refresh(itemId, index, isSelect)
    self:_InitItemGrid()
    self._Index = index
    if XTool.IsNumberValid(itemId) then
        self._Grid:Open()
        self._Grid:Refresh(itemId)
        if isSelect then
            self._Grid:OnClick()
        end
        self.PanelEmpty.gameObject:SetActiveEx(false)
    else
        self._Grid:Close()
        self.PanelEmpty.gameObject:SetActiveEx(true)
    end
    self:SetSelect(isSelect)
end

function XUiBigWorldBackpackItem:SetLock(isLock)
    self.Lock.gameObject:SetActiveEx(isLock)
end

function XUiBigWorldBackpackItem:SetSelect(isSelect)
    self.PanelSelect.gameObject:SetActiveEx(isSelect)
end

function XUiBigWorldBackpackItem:ShowReddot(isShow)
    self.Red.gameObject:SetActiveEx(isShow)
end

-- region 私有方法

function XUiBigWorldBackpackItem:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    -- XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnGoClick, true)
end

function XUiBigWorldBackpackItem:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldBackpackItem:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldBackpackItem:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldBackpackItem:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldBackpackItem:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldBackpackItem:_RefreshConsume()
    
end

function XUiBigWorldBackpackItem:_InitItemGrid()
    if not self._Grid then
        self._Grid = XUiGridBWItem.New(self.ItemGrid, self, Handler(self, self.OnGridClick))
    end
end

-- endregion

return XUiBigWorldBackpackItem
