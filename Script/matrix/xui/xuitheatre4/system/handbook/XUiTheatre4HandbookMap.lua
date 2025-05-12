local XUiTheatre4HandbookMapGrid = require("XUi/XUiTheatre4/System/Handbook/XUiTheatre4HandbookMapGrid")

---@class XUiTheatre4HandbookMap : XUiNode
---@field PanelSecond UnityEngine.RectTransform
---@field RImgMap UnityEngine.UI.RawImage
---@field Map1 UnityEngine.RectTransform
---@field Map2 UnityEngine.RectTransform
---@field Map3 UnityEngine.RectTransform
---@field Map4 UnityEngine.RectTransform
---@field Map5 UnityEngine.RectTransform
---@field Map6 UnityEngine.RectTransform
---@field Map7 UnityEngine.RectTransform
---@field Map8 UnityEngine.RectTransform
---@field Map9 UnityEngine.RectTransform
---@field Map10 UnityEngine.RectTransform
---@field Map11 UnityEngine.RectTransform
---@field Map12 UnityEngine.RectTransform
---@field Map13 UnityEngine.RectTransform
---@field Map14 UnityEngine.RectTransform
---@field Map15 UnityEngine.RectTransform
---@field Map16 UnityEngine.RectTransform
---@field Map17 UnityEngine.RectTransform
---@field Map18 UnityEngine.RectTransform
---@field Map19 UnityEngine.RectTransform
---@field Map20 UnityEngine.RectTransform
---@field _Control XTheatre4Control
local XUiTheatre4HandbookMap = XClass(XUiNode, "XUiTheatre4HandbookMap")

-- region 生命周期
function XUiTheatre4HandbookMap:OnStart()
    ---@type XUiTheatre4HandbookMapGrid[]
    self._MapGridList = {}

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiTheatre4HandbookMap:OnEnable()
    self:_Refresh()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiTheatre4HandbookMap:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiTheatre4HandbookMap:OnDestroy()

end

-- endregion

-- region 私有方法

function XUiTheatre4HandbookMap:_RegisterButtonClicks()
    -- 在此处注册按钮事件
end

function XUiTheatre4HandbookMap:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiTheatre4HandbookMap:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiTheatre4HandbookMap:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiTheatre4HandbookMap:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiTheatre4HandbookMap:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiTheatre4HandbookMap:_Refresh()
    local entitys = self._Control.SystemControl:GetMapIndexEntitys()

    if not XTool.IsTableEmpty(entitys) then
        for index, entity in pairs(entitys) do
            ---@type XTheatre4MapIndexConfig
            local config = entity:GetConfig()
            local location = config:GetId()
            local mapObject = self["Map" .. location]

            if not mapObject then
                XLog.Error("未找到节点Map" .. location)
            else
                mapObject.gameObject:SetActiveEx(true)
                local mapGrid = self._MapGridList[index]

                if not mapGrid then
                    local mapGridObject = XUiHelper.Instantiate(self.PanelSecond, mapObject)

                    ---@type XUiTheatre4HandbookMapGrid
                    mapGrid = XUiTheatre4HandbookMapGrid.New(mapGridObject, self)
                    self._MapGridList[index] = mapGrid
                end

                mapGrid:Open()
                mapGrid:Refresh(entity)
            end
        end
        for i = #entitys + 1, #self._MapGridList do
            self._MapGridList[i]:Close()
        end
    else
        for _, grid in pairs(self._MapGridList) do
            grid:Close()
        end
    end
end

function XUiTheatre4HandbookMap:_InitUi()
    self.PanelSecond.gameObject:SetActiveEx(false)
end

-- endregion

return XUiTheatre4HandbookMap
