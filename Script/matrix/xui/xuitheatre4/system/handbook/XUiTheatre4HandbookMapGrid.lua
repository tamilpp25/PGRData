---@class XUiTheatre4HandbookMapGrid : XUiNode
---@field TxtChapter UnityEngine.UI.Text
---@field ImgLock UnityEngine.UI.Image
---@field _Control XTheatre4Control
local XUiTheatre4HandbookMapGrid = XClass(XUiNode, "XUiTheatre4HandbookMapGrid")

-- region 生命周期
function XUiTheatre4HandbookMapGrid:OnStart()
    self:_RegisterButtonClicks()
end

function XUiTheatre4HandbookMapGrid:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiTheatre4HandbookMapGrid:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiTheatre4HandbookMapGrid:OnDestroy()

end
-- endregion

---@param entity XTheatre4MapIndexEntity
function XUiTheatre4HandbookMapGrid:Refresh(entity)
    ---@type XTheatre4MapIndexConfig
    local config = entity:GetConfig()

    self.ImgLock.gameObject:SetActiveEx(not entity:IsUnlock())
    self.ImgLocation.gameObject:SetActiveEx(entity:IsUnlock())
    self.TxtChapter.text = config:GetName()
end

-- region 私有方法

function XUiTheatre4HandbookMapGrid:_RegisterButtonClicks()
    -- 在此处注册按钮事件
end

function XUiTheatre4HandbookMapGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiTheatre4HandbookMapGrid:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiTheatre4HandbookMapGrid:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiTheatre4HandbookMapGrid:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiTheatre4HandbookMapGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

-- endregion

return XUiTheatre4HandbookMapGrid
