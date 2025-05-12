local XUiGameMainSpine = XClass(nil, 'XUiGameMainSpine')

function XUiGameMainSpine:Ctor(spineObj)
    self.SpineObj = spineObj
    ---@type Spine.Unity.SkeletonAnimation[]|Spine.Unity.SkeletonGraphic[]
    self.UiSpineObjListDir = {}
    --todo：暂时移除旧动画
    --self:InitSpineObjs()
end

function XUiGameMainSpine:InitSpineObjs()
    if XTool.UObjIsNil(self.SpineObj) then
        return
    end
    
    local SkeletonAnimationCSArray = self.SpineObj.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonAnimation))
    local SkeletonGraphicCSArray = self.SpineObj.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonGraphic))
    if SkeletonAnimationCSArray.Length ~= 0 or SkeletonGraphicCSArray.Length ~= 0 then
        local spineObjList = {}
        for j = 0, SkeletonAnimationCSArray.Length - 1, 1 do
            spineObjList[#spineObjList + 1] = SkeletonAnimationCSArray[j]
        end
        for j = 0, SkeletonGraphicCSArray.Length - 1, 1 do
            spineObjList[#spineObjList + 1] = SkeletonGraphicCSArray[j]
        end
        if not XTool.IsTableEmpty(spineObjList) then
            self.UiSpineObjListDir[#self.UiSpineObjListDir + 1] = spineObjList
        end
    end
end

---Spine对象组播放动画
function XUiGameMainSpine:PlaySpineAnimation(fromAnim, toAnim)
    if not XTool.IsTableEmpty(self.UiSpineObjListDir) then
        for _, uiSpineObjList in pairs(self.UiSpineObjListDir) do
            for _, uiSpineObj in ipairs(uiSpineObjList) do
                if toAnim then
                    self:_PlaySpineObjAnimation(uiSpineObj, fromAnim, toAnim)
                else
                    self:_PlaySpineObjAnimation(uiSpineObj, fromAnim)
                end
            end
        end
    end
end

---spine对象播放动画
function XUiGameMainSpine:_PlaySpineObjAnimation(spineObject, fromAnim, toAnim)
    if XTool.UObjIsNil(spineObject) then return end

    -- 判断Spine是否存在动画轨道
    local isHaveFrom = fromAnim and spineObject.skeletonDataAsset:GetSkeletonData(false):FindAnimation(fromAnim)
    local isHaveTo = toAnim and spineObject.skeletonDataAsset:GetSkeletonData(false):FindAnimation(toAnim)
    if isHaveFrom then
        --Delegate += 操作Lua写法
        local cb
        cb = function(track)
            if track.Animation.Name == fromAnim and isHaveTo then
                spineObject.AnimationState:SetAnimation(0, toAnim, true)
                spineObject.AnimationState:Complete('-', cb)
            end
        end
        spineObject.AnimationState:Complete('+', cb)
        -- 没有toAnim则fromAnim循环
        spineObject.AnimationState:SetAnimation(0, fromAnim, not isHaveTo)
    elseif isHaveTo then
        spineObject.AnimationState:SetAnimation(0, toAnim, true)
    end
end

return XUiGameMainSpine