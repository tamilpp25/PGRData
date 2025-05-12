local pairs = pairs
local tableInsert = table.insert
local SPINE_INDEX_OFFSET = 100 -- spine位置的偏移值
local ALL_BG_INDEX = 999

local XMovieActionSetGray = XClass(XMovieActionBase, "XMovieActionSetGray")

function XMovieActionSetGray:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.Value = XMath.Clamp(paramToNumber(params[1]), 0, 1)
    self.IndexList = {}
    local maxParamNum = XMovieConfigs.MAX_ACTOR_NUM + 1
    for i = 1, maxParamNum do
        local index = paramToNumber(params[i + 1])
        if index ~= 0 then
            tableInsert(self.IndexList, index)
        end
    end
end

function XMovieActionSetGray:OnRunning()
    local value = self.Value
    local maxActorNum = XMovieConfigs.MAX_ACTOR_NUM
    local indexList = self.IndexList
    local setValue = false

    for _, index in pairs(indexList) do
        if index > 0 and index <= maxActorNum then
            local actor = self.UiRoot:GetActor(index)
            actor:SetGrayScale(value)
            setValue = true
        elseif index > SPINE_INDEX_OFFSET and index <= SPINE_INDEX_OFFSET + maxActorNum then
            local actor = self.UiRoot:GetSpineActor(index - SPINE_INDEX_OFFSET)
            actor:SetGrayScale(value)
            setValue = true
        else
            self:SetBgGray(index, value)
            self:SetLeftTitleGray(value)
            setValue = true
        end
    end

    if not setValue then
        self:SetAllBgGray(value)
        self:SetLeftTitleGray(value)
        for index = 1, maxActorNum do
            local actor = self.UiRoot:GetActor(index)
            actor:SetGrayScale(value)
        end

        for index = 1, XMovieConfigs.MAX_SPINE_ACTOR_NUM do
            local actor = self.UiRoot:GetSpineActor(index)
            actor:SetGrayScale(value)
        end
    end
end

-- 设置左边标题的灰度
function XMovieActionSetGray:SetLeftTitleGray(value)
    local controllerComponents = self.UiRoot.PanelLeftTitle:GetComponentsInChildren(typeof(CS.XUiMaterialController))
    for i = 0, controllerComponents.Length - 1 do
        local controller = controllerComponents[i]
        controller:SetGrayScale(value)
    end
end

-- 设置背景的灰度值
function XMovieActionSetGray:SetBgGray(index, value)
    if index == ALL_BG_INDEX then
        self:SetAllBgGray(value)
    else
        local bgIndex = index % 1000
        local rImgBg = self.UiRoot["RImgBg" .. bgIndex]
        local component = rImgBg:GetComponent("XUiMaterialController")
        if not component then
            component = rImgBg.gameObject:AddComponent(typeof(CS.XUiMaterialController))
        end
        component:SetGrayScale(value)
    end
end

-- 设置所有背景的灰度值
function XMovieActionSetGray:SetAllBgGray(value)
    local index = 1
    while(true) do
        local bg = self.UiRoot["RImgBg" .. index]
        if not bg then break end

        local component = bg:GetComponent("XUiMaterialController")
        if not component then
            component = bg.gameObject:AddComponent(typeof(CS.XUiMaterialController))
        end
        component:SetGrayScale(value)
        index = index + 1
    end
end

return XMovieActionSetGray