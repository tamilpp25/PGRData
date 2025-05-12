local XUiBigWorldTeachContent = require("XUi/XUiBigWorld/XTeach/Common/XUiBigWorldTeachContent")

---@class XUiBigWorldPopupTeach : XBigWorldUi
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field PanelTeachContent UnityEngine.RectTransform
---@field _Control XBigWorldTeachControl
local XUiBigWorldPopupTeach = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPopupTeach")

function XUiBigWorldPopupTeach:OnAwake()
    self._TeachId = 0

    ---@type XUiBigWorldTeachContent
    self._ContentUi = XUiBigWorldTeachContent.New(self.PanelTeachContent, self)

    self:_RegisterButtonClicks()
end

function XUiBigWorldPopupTeach:OnStart(teachId)
    self._TeachId = teachId

    self._Control:ReadTeach(teachId)
    self._ContentUi:Refresh(teachId)
end

function XUiBigWorldPopupTeach:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldPopupTeach:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldPopupTeach:OnDestroy()
end

-- region 按钮事件

function XUiBigWorldPopupTeach:OnBtnTanchuangCloseClick()
    self:Close()
end

-- endregion

-- region 私有方法

function XUiBigWorldPopupTeach:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnTanchuangClose.CallBack = Handler(self, self.OnBtnTanchuangCloseClick)
end

function XUiBigWorldPopupTeach:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldPopupTeach:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldPopupTeach:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldPopupTeach:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldPopupTeach:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

-- endregion

return XUiBigWorldPopupTeach
