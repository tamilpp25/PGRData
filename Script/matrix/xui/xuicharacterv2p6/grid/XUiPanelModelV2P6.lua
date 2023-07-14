-- 整个成员系统的镜头model管理
-- Parent是CharacterSystem
---@class XUiPanelModelV2P6
local XUiPanelModelV2P6 = XClass(XUiNode, "XUiPanelModelV2P6")
local XUiGridSkillEffectBall3D = require("XUi/XUiCharacterV2P6/Grid/XUiGridSkillEffectBall3D")

local BtnNodeName = "BtnNodeName"
local BtnDropName = "BtnDropName"

function XUiPanelModelV2P6:OnStart()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    self.SeleQuality = nil
    self.BigBallGridDic = {}
    self.NodeAllTagsDic = {}    --每次切换球都要刷新
    self.TagBtnSkillEventDic = {} --记录是否注册过bubble里的skillBtn事件，每次切换球都要刷新
    self.Resources = {}
    
    self:InitCamera()
end

function XUiPanelModelV2P6:InitCamera()
    -- 根据enumcost的CameraV2P6依次填入
    self.CameraFars = 
    {
        self.UiCamFarMain,
        self.UiCamFarTrain,
        self.UiCamFarQuality,
        self.UiCamFarLvUseItem,
        self.UiCamFarQualitySingle,
        self.UiCamFarQualityOverview,
        self.UiCamFarQualityUpgradeDetail,
        self.UiCamFarCharLeftMove,
    }

    self.CameraNears = 
    {
        self.UiCamNearMain,
        self.UiCamNearTrain,
        self.UiCamNearQuality,
        self.UiCamNearLvUseItem,
        self.UiCamNearQualitySingle,
        self.UiCamNearQualityOverview,
        self.UiCamNearQualityUpgradeDetail,
        self.UiCamNearCharLeftMove,
    }
end

-- 子界面通过该接口设置相机
function XUiPanelModelV2P6:SetCamera(targetIndex)
    for i, cameraTrans in pairs(self.CameraFars) do
        cameraTrans.gameObject:SetActiveEx(targetIndex == i)
    end

    for i, cameraTrans in pairs(self.CameraNears) do
        cameraTrans.gameObject:SetActiveEx(targetIndex == i)
    end
end

function XUiPanelModelV2P6:SetSelectQuality(quality)
    self.SeleQuality = quality
end

function XUiPanelModelV2P6:SetBtnDropCb(cb)
    self.BtnDropCb = cb
end

function XUiPanelModelV2P6:InitQualitySingleRelatedBtn()
    -- node
    for i = 1, XEnumConst.CHARACTER.MAX_QUALITY_STAR do
        local panel = self["Node"..i]
        local btn = panel:Find("Btn"):GetComponent("XUiButton")
        self[BtnNodeName..i] = btn
        XUiHelper.RegisterClickEvent(self, btn, function ()
            if not self.SeleQuality then
                return
            end
            self:ShowNodeBubble(i)
        end)
    end

    -- btnDrop
    local btnLists = {}
    for i = 1, XEnumConst.CHARACTER.MAX_QUALITY do
        local panel = self.BtnGroupPanelDrop.transform:FindTransform("BtnDrop"..i)
        local btn = panel:GetComponent("XUiButton")
        table.insert(btnLists, btn)
        self[BtnDropName..i] = btn
        XUiHelper.RegisterClickEvent(self, btn, function ()
            if not self.SeleQuality then
                return
            end
            local character = self.Parent.CurCharacter
        
            -- 不能进入比初始品质还低的品质球界面
            local initQuality = self.CharacterAgency:GetCharacterInitialQuality(character.Id)
            if i < initQuality then
                return
            end
            if self.BtnDropCb then
                self.BtnDropCb(i)
            end

            self.ImgEffectHuanBigball.gameObject:SetActiveEx(false)
            self.ImgEffectHuanBigball.gameObject:SetActiveEx(true)

            self:OnBtnCloseBubbleClick()

            self:PlayCharModelAnime("PanelBigBallQieHuan")
        end)
    end

    -- group不做业务逻辑 仅做按钮互斥效果
    self.BtnGroupPanelDrop:Init(btnLists, function ()
    end)

    -- 初始化大球预置体
    local bigBallPath = "Assets/Product/Ui/ComponentPrefab/Character/PanelEffectBallBig.prefab"
    local resource = CS.XResourceManager.Load(bigBallPath)
    table.insert(self.Resources, resource)
    local allBigBall = CS.UnityEngine.Object.Instantiate(resource.Asset, self.EffectBallRoot).transform
    local childCount = allBigBall.childCount
    local gridList = {}
    for i = 0, childCount - 1 do
        table.insert(gridList, allBigBall:GetChild(i))
    end
    for i = 1, #gridList do
        local grid = gridList[i]
        grid:SetParent(self.PanelEffectBallBig)
        grid.localPosition = CS.UnityEngine.Vector3.zero
        grid.localEulerAngles = CS.UnityEngine.Vector3.zero
    end

    XUiHelper.RegisterClickEvent(self, self.BtnCloseBubble, self.OnBtnCloseBubbleClick)
end

function XUiPanelModelV2P6:ShowNodeBubble(index)
    self:RefreshBubbleInfo(index)
    for i = 1, XEnumConst.CHARACTER.MAX_QUALITY_STAR do
        if i ~= self.CurNodeIndex then
            local tags = self.NodeAllTagsDic[i]
            if not tags then
                local node = self["Node"..i]
                tags = node:FindAllTransforms("Tag")
                self.NodeAllTagsDic[i] = tags
            end
            for j = 0, tags.Count - 1 do
                local tag = tags[j]
                tag.gameObject:SetActiveEx(index == i)
            end
        end
    end
end

function XUiPanelModelV2P6:RefreshBubbleInfo(index)
    local characterId = self.Parent.CurCharacter.Id
    local character = self.CharacterAgency:GetCharacter(characterId)
    local seleStar = index
    local seleQuality = self.SeleQuality

    local tags = self.NodeAllTagsDic[index]
    if not tags then
        local node = self["Node"..index]
        tags = node:FindAllTransforms("Tag")
        self.NodeAllTagsDic[index] = tags
    end
    for j = 0, tags.Count - 1 do
        local infoRootTrans = tags[j]
        -- 阶段x 文本
        local isActive = character.Star >= seleStar
        infoRootTrans:FindTransform("TxtTitle"):GetComponent("Text").text = XUiHelper.GetText("CharacterQualityStar", seleStar)
        infoRootTrans:FindTransform("TxtStateOn").gameObject:SetActiveEx(isActive)
        infoRootTrans:FindTransform("TxtStateOff").gameObject:SetActiveEx(not isActive)
    
        -- 属性加成文本
        local attribs = XCharacterConfigs.GetCharCurStarAttribsV2P6(character.Id, seleQuality, seleStar)
        for k, v in pairs(attribs or {}) do
            local value = FixToDouble(v)
            if value > 0 then
                infoRootTrans:FindTransform("TxtAttribute"):GetComponent("Text").text = XAttribManager.GetAttribNameByIndex(k) .. "+" .. string.format("%.2f", value)
                break
            end
        end
    
        -- 技能文本
        local data = XCharacterConfigs.GetCharSkillQualityApartDicByQuality(characterId, seleQuality)
        local btnSkill = infoRootTrans:FindTransform("BtnSkill"):GetComponent("XUiButton")
        if XTool.IsTableEmpty(data) then
            btnSkill.gameObject:SetActiveEx(false)
            goto continueBubble
        end
    
        local curApartIds = data[seleStar]
        if not curApartIds then
            btnSkill.gameObject:SetActiveEx(false)
            goto continueBubble
        end
    
        local curApartId = curApartIds[1]
        self.SkillApartId = curApartId
        local skillName = XCharacterConfigs.GetCharSkillQualityApartName(curApartId)
        local skillLevel = XCharacterConfigs.GetCharSkillQualityApartLevel(curApartId)
        btnSkill.gameObject:SetActiveEx(true)
        btnSkill:SetNameByGroup(0, skillName.."Lv"..skillLevel)

        -- 注册技能跳转按钮
        local isRig = self.TagBtnSkillEventDic[btnSkill]
        if not isRig then
            XUiHelper.RegisterClickEvent(self, btnSkill, function ()
                self:OpenSkillInfo(curApartId)
            end)
            self.TagBtnSkillEventDic[btnSkill] = true
        end
        :: continueBubble ::
    end
end

function XUiPanelModelV2P6:OpenSkillInfo(skillApartId)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterSkill) then
        return
    end
    local characterId = self.Parent.CurCharacter.Id
    local skillId = XCharacterConfigs.GetCharSkillQualityApartSkillId(skillApartId)

    local skillGroupId, index = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
    local skillPosToGroupIdDic = XCharacterConfigs.GetChracterSkillPosToGroupIdDic(characterId)
    for pos, group in ipairs(skillPosToGroupIdDic) do
        for gridIndex, id in ipairs(group) do
            if id == skillGroupId then
                XLuaUiManager.Open("UiSkillDetailsParentV2P6", characterId, XCharacterConfigs.SkillDetailsType.Normal, pos, gridIndex)
                return
            end
        end
    end
end

function XUiPanelModelV2P6:OnBtnCloseBubbleClick()
    for i = 1, XEnumConst.CHARACTER.MAX_QUALITY_STAR do
        if i ~= self.CurNodeIndex then
            local tags = self.NodeAllTagsDic[i]
            if not tags then
                local node = self["Node"..i]
                tags = node:FindAllTransforms("Tag")
                self.NodeAllTagsDic[i] = tags
            end
            for j = 0, tags.Count - 1 do
                local tag = tags[j]
                tag.gameObject:SetActiveEx(false)
            end
        end
    end
end

-- 进化single界面用的按钮。外部调用. 调用前必须要设置品质 setQuality
---@param isActive 激活节点
---@param isEvo 球进化
function XUiPanelModelV2P6:RefreshSingleBigBall(isActiveNode, isEvo)
    if not self.SeleQuality then
        return
    end
    self:ResetBtnNodeData()

    self.BtnGroupPanelDrop:SelectIndex(self.SeleQuality)
    local character = self.Parent.CurCharacter
    local qualityConfig = self.CharacterAgency:GetQualityTemplate(character.Id, self.SeleQuality)

    -- 刷新前关闭所有气泡
    self:OnBtnCloseBubbleClick()
    -- 刷新特效品质球的10个节点
    for i = 1, XEnumConst.CHARACTER.MAX_QUALITY_STAR do
        local isAttrEmpty = XTool.IsTableEmpty(qualityConfig.AttrId) or not qualityConfig.AttrId[i]
        local panel = self["Node"..i]
        panel.gameObject:SetActiveEx(not isAttrEmpty)
        -- 有节点再刷新
        if not isAttrEmpty then
            local btn = self[BtnNodeName..i]
            -- 激活
            local isActive = (character.Star >= i and character.Quality == self.SeleQuality) or (character.Quality > self.SeleQuality) -- 已激活的node
            local isCurrent = ((character.Star + 1 == i) or (character.Star == 0 and i == 1)) and character.Quality == self.SeleQuality -- 特殊部分：若这个球是激活中，且阶段为0/10，则第一个按钮的状态应该是：当前状态
            local normal = btn.transform:Find("Normal")
            local select = btn.transform:Find("Select")
            local disable = btn.transform:Find("Disable")
            local skillTipsShadow = btn.transform:FindTransform("SkillTipsShadow")
            local skillTips = btn.transform:FindTransform("SkillTips")
            local bgSkill = btn.transform:FindTransform("BgSkill")

            normal.gameObject:SetActiveEx(isActive and not isCurrent)
            select.gameObject:SetActiveEx(isCurrent)
            disable.gameObject:SetActiveEx(not isActive)
            if isCurrent then
                self.CurNodeIndex = i
                select:Find("Tag").gameObject:SetActiveEx(true)
                self:RefreshBubbleInfo(i)
            end

            -- 技能图标
            local data = XCharacterConfigs.GetCharSkillQualityApartDicByQuality(character.Id, self.SeleQuality)
            local isActiveSkill = nil
            if not XTool.IsTableEmpty(data) then
                local curApartIds = data[i]
                isActiveSkill = not XTool.IsTableEmpty(curApartIds)
            end
            if isActiveSkill then
                skillTipsShadow:Find("Image1"):GetComponent("Image"):SetSprite(CS.XGame.ClientConfig:GetString("PanelCharBigBallBgNormal1"))
                skillTipsShadow:Find("Image2"):GetComponent("Image"):SetSprite(CS.XGame.ClientConfig:GetString("PanelCharBigBallBgNormal2"))
                skillTips:Find("Image1"):GetComponent("Image"):SetSprite(CS.XGame.ClientConfig:GetString("PanelCharBigBallBgNormal1"))
                skillTips:Find("Image2"):GetComponent("Image"):SetSprite(CS.XGame.ClientConfig:GetString("PanelCharBigBallBgNormal2"))
            else
                skillTipsShadow:Find("Image1"):GetComponent("Image"):SetSprite(CS.XGame.ClientConfig:GetString("PanelCharBigBallBgSpecial1"))
                skillTipsShadow:Find("Image2"):GetComponent("Image"):SetSprite(CS.XGame.ClientConfig:GetString("PanelCharBigBallBgSpecial2"))
                skillTips:Find("Image1"):GetComponent("Image"):SetSprite(CS.XGame.ClientConfig:GetString("PanelCharBigBallBgSpecial1"))
                skillTips:Find("Image2"):GetComponent("Image"):SetSprite(CS.XGame.ClientConfig:GetString("PanelCharBigBallBgSpecial2"))
            end
            bgSkill.gameObject:SetActiveEx(isActiveSkill)

            -- 名字
            local qualityDesc = XCharacterConfigs.GetCharQualityDesc(self.SeleQuality)
            btn:SetNameByGroup(0, qualityDesc..i)
        end
    end

    -- 刷新下方品质球切换按钮
    local initQuality = self.CharacterAgency:GetCharacterInitialQuality(character.Id)
    for i = 1, XEnumConst.CHARACTER.MAX_QUALITY do
        local btnDrop = self[BtnDropName..i]
        if i < initQuality then
            btnDrop.gameObject:SetActiveEx(false)
        else
            btnDrop.gameObject:SetActiveEx(true)
        end
        local curQualityState = self.CharacterAgency:GetQualityState(character.Id, i)
        btnDrop.transform:Find("Disable").gameObject:SetActiveEx(curQualityState == XEnumConst.CHARACTER.QualityState.Lock)
    end

    -- 刷新当前球里的特效 
    self:RefreshBigBallEffect(self.SeleQuality, isActiveNode, isEvo)
    self:OpenBigEffectBall(self.SeleQuality)
end

-- 切换球 重置数据
function XUiPanelModelV2P6:ResetBtnNodeData()
    self.NodeAllTagsDic = {}
    self.TagBtnSkillEventDic = {}
    self.CurNodeIndex = nil
end

function XUiPanelModelV2P6:OpenBigEffectBall(quality)
    for i = 1, XEnumConst.CHARACTER.MAX_QUALITY do
        local bigBallTrans = self.PanelEffectBallBig:FindTransform("EffectBallBig".. i)
        bigBallTrans.gameObject:SetActiveEx(quality == i)
    end
end

-- single界面大球特效相关
function XUiPanelModelV2P6:RefreshBigBallEffect(quality, isActive, isEvo)
    local character = self.Parent.CurCharacter
    local bigBallTrans = self.PanelEffectBallBig:FindTransform("EffectBallBig".. quality)
    
    local obj = self.BigBallGridDic[quality]
    if not obj then
        obj = {}
        XTool.InitUiObjectByUi(obj, bigBallTrans) -- 将3d的内容加进这
        self.BigBallGridDic[quality] = obj
    end

    -- 刷新 先记录状态、最后在设置active
    local EffectBallBigInside1 = false
    local EffectBallBigInside2 = false
    local EffectBallBigOutside1 = false
    local EffectBallBigOutside2 = false
    local EffectBallBigDecorate1 = false
    local EffectBallBigDecorate2 = false
    local EffectBallBigExplode = false
    local EffectBallBigUpdate = false
    
    -- 球内分阶段显示 
    local curPerform = self.CharacterAgency:GetCharQualityPerformArea(character.Id, quality)
    if curPerform == XEnumConst.CHARACTER.PerformState.One then
        EffectBallBigInside1 = true
        EffectBallBigOutside1 = true
    elseif curPerform == XEnumConst.CHARACTER.PerformState.Two then
        EffectBallBigInside2 = true
        EffectBallBigOutside1 = true
    elseif curPerform == XEnumConst.CHARACTER.PerformState.Three then
        EffectBallBigInside2 = true
        EffectBallBigOutside2 = true
    elseif curPerform == XEnumConst.CHARACTER.PerformState.Four then --第四阶段有两种可能，1：球的10个点全部进化。2：当前是最后一个sss+品质球
        EffectBallBigInside2 = true
        EffectBallBigOutside2 = true

        -- 分球品质显示
        if quality >= self.CharacterAgency:GetCharMaxQuality(character.Id) then
            EffectBallBigDecorate1 = true
            EffectBallBigDecorate2 = true
        end
    end

    obj.EffectBallBigInside1.gameObject:SetActiveEx(EffectBallBigInside1)
    obj.EffectBallBigInside2.gameObject:SetActiveEx(EffectBallBigInside2)
    obj.EffectBallBigOutside1.gameObject:SetActiveEx(EffectBallBigOutside1)
    obj.EffectBallBigOutside2.gameObject:SetActiveEx(EffectBallBigOutside2)
    obj.EffectBallBigDecorate1.gameObject:SetActiveEx(EffectBallBigDecorate1)
    obj.EffectBallBigDecorate2.gameObject:SetActiveEx(EffectBallBigDecorate2)
    
    -- 激活或进化效果
    if isActive then
        obj.EffectBallBigExplode.gameObject:SetActiveEx(false)
        obj.EffectBallBigExplode.gameObject:SetActiveEx(true)
    else
        obj.EffectBallBigExplode.gameObject:SetActiveEx(false)
    end
    if isEvo then
        obj.EffectBallBigUpdate.gameObject:SetActiveEx(false)
        obj.EffectBallBigUpdate.gameObject:SetActiveEx(true)
    else
        obj.EffectBallBigUpdate.gameObject:SetActiveEx(false)
    end
end

--region 动态列表相关
function XUiPanelModelV2P6:SetDynamicTableClickCb(cb)
    self.OnSelectCb = cb
end

function XUiPanelModelV2P6:InitDynamicTable3D()
    local smallBallPath = "Assets/Product/Ui/ComponentPrefab/Character/PanelEffectBallSmall.prefab"
    local resource = CS.XResourceManager.Load(smallBallPath)
    table.insert(self.Resources, resource)
    local allSmallBall = CS.UnityEngine.Object.Instantiate(resource.Asset, self.EffectBallRoot.transform).transform
    local childCount = allSmallBall.childCount
    local gridList = {}
    for i = 0, childCount - 1 do
        table.insert(gridList, allSmallBall:GetChild(i).gameObject)
    end

    self.DynamicTable3D = XDynamicTableFixed3D.New(self.PanelBallList)
    self.DynamicTable3D:SetProxy(XUiGridSkillEffectBall3D, self, self)
    self.DynamicTable3D:SetDelegate(self)
    self.DynamicTable3D:GetImpl():SetPreGirdsList(gridList)

    self.DynamicTable3D:SetDynamicEventDelegate(function (event, index, grid)
        self:OnDynamicTableEvent(event, index, grid)
    end)
end

function XUiPanelModelV2P6:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local curQuality = self.InitQuality + index - 1 
        local characterId = self.Parent.CurCharacter.Id
        grid:Refresh(characterId, curQuality)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local curSelectQuality = self.InitQuality + (index - 1)
        if self.OnSelectCb then
            self.OnSelectCb(curSelectQuality)
        end
    end
end

function XUiPanelModelV2P6:RefreshDynamicTable3D(index)
    -- 根据初始品质设置特效球个数
    local characterId = self.Parent.CurCharacter.Id
    self.InitQuality = self.CharacterAgency:GetCharacterInitialQuality(characterId)
    self.DynamicTable3D:SetStartGridLuaIndex(self.InitQuality)
    local dataList = {}
    local qIndex = 1
    for i = self.InitQuality, XEnumConst.CHARACTER.MAX_QUALITY, 1 do
        table.insert(dataList, {Index = qIndex, Quality = i})
        qIndex = qIndex + 1
    end
    self.DynamicTable3D:SetDataSource(dataList)
    self.DynamicTable3D:ReloadDataSync(index, true)
end

function XUiPanelModelV2P6:RefreshDynamicTable3DByEvoPerform(nextQuality, cb)
    local characterId = self.Parent.CurCharacter.Id
    local initQuality = self.CharacterAgency:GetCharacterInitialQuality(characterId)
    local targetCsIndex = nextQuality - initQuality
    local targetLuaIndex = targetCsIndex + 1
    local curLuaIndex = targetCsIndex
    local curGrid = self.DynamicTable3D:GetGridByIndex(curLuaIndex)
    -- 播放线的演出 todo
    curGrid:Refresh(characterId, nextQuality - 1)
    XScheduleManager.ScheduleOnce(function ()
        curGrid:PlayLineAnime() -- 放到下一帧播放 因为当前的动画还没load出来
    end, 0)
    local moveCb = function ()
        local targetGrid = self.DynamicTable3D:GetGridByIndex(targetLuaIndex)
        targetGrid:Refresh(characterId, nextQuality, true)
        if cb then
            cb()
        end
    end

    self.DynamicTable3D:FocusIndex(targetCsIndex, 3, moveCb)
end

-- 看小球文字的相机和动态列表同步打开
function XUiPanelModelV2P6:SetDynamicTableActive(flag)
    self.PanelBallList.gameObject:SetActiveEx(flag)
end

function XUiPanelModelV2P6:SetCameraQualityActive(flag)
    self.UiCamUiQuality.gameObject:SetActiveEx(flag)
end
--endregion 动态列表相关结束

-- 专门做角色同步的相机、这里被同步位置的相机是专门用来看镜头里的ui的，但是为了适配和角色正确的位置、需要动态改动
function XUiPanelModelV2P6:FixUiCameraMainToEffectBall()
    self.UiCamUiMain.transform.position = self.UiCamNearMain.transform.position
    self.UiCamUiMain.transform.localEulerAngles = self.UiCamNearMain.transform.localEulerAngles

    self.UiCamUiQuality.transform.position = self.UiCamNearQuality.transform.position
    self.UiCamUiQuality.transform.localEulerAngles = self.UiCamNearQuality.transform.localEulerAngles
end

-- 开关进化single界面的相关物件
function XUiPanelModelV2P6:SetQualitySingleRelated(flag)
    -- 不启用QualitySingle相关的镜头了，由动画控制Quality的轨迹实现
    self.PanelBigBall.gameObject:SetActiveEx(flag) -- 镜头2DUi，大球的十个节点
    self:SetPanelEffectBallBigActive(flag)  -- 3D大球实体
    self.EffectBg3.gameObject:SetActiveEx(flag) -- 在这个界面展示的场景特效
    if flag then
        self.EffectBg3:LoadPrefab(CS.XGame.ClientConfig:GetString("FxUiCharacterV2Sanjiao1"))
    end
end

-- 只打开特效球
function XUiPanelModelV2P6:SetPanelEffectBallBigActive(flag)
    self.PanelEffectBallBig.gameObject:SetActiveEx(flag)
end

function XUiPanelModelV2P6:PlayCharModelAnime(animeName, finCb)
    local animTrans = self.Animation:FindTransform(animeName)
    if not animTrans.gameObject.activeInHierarchy then
        return
    end
    animTrans:PlayTimelineAnimation(finCb)
end

function XUiPanelModelV2P6:OnRelease()
    for k, obj in pairs(self.Resources) do
        CS.XResourceManager.Unload(obj)
    end
    self:ResetBtnNodeData()
end

return XUiPanelModelV2P6