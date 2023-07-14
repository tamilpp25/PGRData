XUiArchiveMonsterSynopsis = XClass(nil, "XUiArchiveMonsterSynopsis")

local tableInsert = table.insert
local Object = CS.UnityEngine.Object
local LockNameText = CS.XTextManager.GetText("ArchiveLockNameText")
local CSTextManagerGetText = CS.XTextManager.GetText

local childUiComment = "UiArchiveMonsterComment"
local childUiEvaluate = "UiArchiveMonsterEvaluate"

local EvaluateOneForAll = XArchiveConfigs.EvaluateOnForAll
local InfoMax = 4
local TagMax = 3
local ScoreMax = 5
local DifficultyMax = 5

function XUiArchiveMonsterSynopsis:Ctor(ui, data, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.Data = data
    self.Base = base
    self.MonsterInfo = {}
    self.MonsterSetting = {}
    self.MonsterFeatures = {}
    self.MonsterSkillState = {}
    self.PlayerEvaluate = {}

    self.MyDisCount = {}
    self.MyLikeCount = {}
    self.DisCount = {}
    self.LikeCount = {}

    self.LikeStatus = {}
    self.OldLikeStatus = {}
    self.IsLikeInit = {}

    self.CurEvaluateData = {}
    self.CurInfoData = {}
    self.CurSkillData = {}
    self.CurSettingData = {}

    self:Init()
end

function XUiArchiveMonsterSynopsis:Destroy()
    self:GiveLikeStatus()
    self.Base:CloseChildUi(childUiComment)
    self.Base:CloseChildUi(childUiEvaluate)
end

function XUiArchiveMonsterSynopsis:Init()
    self:InitMonsterDeatail(self.MonsterInfo, self.MonsterInfoObj)
    self:InitMonsterDeatail(self.MonsterSetting, self.MonsterSettingObj)
    self:InitMonsterDeatail(self.MonsterFeatures, self.MonsterFeaturesObj)
    self:InitMonsterDeatail(self.PlayerEvaluate, self.PlayerEvaluateObj)
    self:InitObjGroup()
    self:SetButtonCallBack()
    self:InitEvaluate()
    self:InitLikeAndDis()
    self:InitRedPoint()
end

function XUiArchiveMonsterSynopsis:InitMonsterDeatail(tmp, obj)
    tmp.Transform = obj.transform
    tmp.GameObject = obj.gameObject
    XTool.InitUiObject(tmp)
end

function XUiArchiveMonsterSynopsis:InitObjGroup()
    self.MonsterInfo.InfoContent = {
        self.MonsterInfo.InfoContent1,
        self.MonsterInfo.InfoContent2,
        self.MonsterInfo.InfoContent3,
        self.MonsterInfo.InfoContent4
    }
    self.MonsterFeatures.TagItemObj = {
        self.MonsterFeatures.TagItemObj1,
        self.MonsterFeatures.TagItemObj2,
        self.MonsterFeatures.TagItemObj3
    }
    self.PlayerEvaluate.TagItemObj = {
        self.PlayerEvaluate.TagItemObj1,
        self.PlayerEvaluate.TagItemObj2,
        self.PlayerEvaluate.TagItemObj3
    }
    self.PlayerEvaluate.GradeIcon = {
        self.PlayerEvaluate.GradeIcon1,
        self.PlayerEvaluate.GradeIcon2,
        self.PlayerEvaluate.GradeIcon3,
        self.PlayerEvaluate.GradeIcon4,
        self.PlayerEvaluate.GradeIcon5
    }
    self.PlayerEvaluate.LevelIcon = {
        self.PlayerEvaluate.LevelIcon1,
        self.PlayerEvaluate.LevelIcon2,
        self.PlayerEvaluate.LevelIcon3,
        self.PlayerEvaluate.LevelIcon4,
        self.PlayerEvaluate.LevelIcon5
    }
end

function XUiArchiveMonsterSynopsis:InitRedPoint()
    XRedPointManager.AddRedPointEvent(self.MonsterInfo.BtnMore, self.OnCheckInfoRedDot, self,
        { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_INFO }, self.Data:GetId())

    XRedPointManager.AddRedPointEvent(self.MonsterSetting.BtnSet, self.OnCheckSettingRedDot, self,
        { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_SETTING }, self.Data:GetId())

    XRedPointManager.AddRedPointEvent(self.MonsterSetting.BtnSkill, self.OnCheckSkillRedDot, self,
        { XRedPointConditions.Types.CONDITION_ARCHIVE_MONSTER_SKILL }, self.Data:GetId())
end

function XUiArchiveMonsterSynopsis:SetButtonCallBack()
    self.PlayerEvaluate.BtnMore.CallBack = function()
        self:OnBtnPlayerEvaluateClick()
    end
    self.BtnEvaluate.CallBack = function()
        self:OnBtnEvaluateClick()
    end

    self.MonsterInfo.BtnMore.CallBack = function()
        self:OnMonsterInfoBtnClick()
    end

    self.MonsterSetting.BtnSet.CallBack = function()
        self:OnMonsterSetBtnClick()
    end

    self.MonsterSetting.BtnSkill.CallBack = function()
        self:OnMonsterSkillStateBtnClick()
    end

end

function XUiArchiveMonsterSynopsis:InitEvaluate()
    self.EvaluateList = XDataCenter.ArchiveManager.GetArchiveMonsterEvaluateList()
    self.MySelfEvaluateList = XDataCenter.ArchiveManager.GetArchiveMonsterMySelfEvaluateList()

    for _, npcId in pairs(self.Data:GetNpcId()) do
        self.IsLikeInit[npcId] = false
        self.LikeStatus[npcId] = self.MySelfEvaluateList[npcId] and self.MySelfEvaluateList[npcId].LikeStatus or XArchiveConfigs.EquipLikeType.NULL
        self.OldLikeStatus[npcId] = self.MySelfEvaluateList[npcId] and self.MySelfEvaluateList[npcId].LikeStatus or XArchiveConfigs.EquipLikeType.NULL
        self.DisCount[npcId] = self.EvaluateList[npcId] and self.EvaluateList[npcId].DislikeCount or 0
        self.LikeCount[npcId] = self.EvaluateList[npcId] and self.EvaluateList[npcId].LikeCount or 0
    end
end

function XUiArchiveMonsterSynopsis:InitLikeAndDis()
    self.LikeBtnGroupList = {}
    self.LikeBtnObjList = {}
    for _, npcId in pairs(self.Data:GetNpcId()) do
        if not self.LikeBtnObjList[npcId] then self.LikeBtnObjList[npcId] = {} end

        local btnGroupObj = Object.Instantiate(self.BtnGroup)
        btnGroupObj.transform:SetParent(self.BtnGroupContent.transform, false)

        self.LikeBtnObjList[npcId].Transform = btnGroupObj.transform
        self.LikeBtnObjList[npcId].GameObject = btnGroupObj.gameObject
        XTool.InitUiObject(self.LikeBtnObjList[npcId])

        self.LikeBtnGroupList[npcId] = btnGroupObj:GetComponent("XUiButtonGroup")
        local btnLikeAndDis = { self.LikeBtnObjList[npcId].BtnStep, self.LikeBtnObjList[npcId].BtnLike }
        self.LikeBtnGroupList[npcId]:Init(btnLikeAndDis, function(index) self:SelectLikeOrDis(npcId, index) end)
        self.LikeBtnGroupList[npcId].CurSelectId = -1
        self.LikeBtnGroupList[npcId].CanDisSelect = true

        if self.LikeStatus[npcId] ~= XArchiveConfigs.EquipLikeType.NULL then
            self.IsLikeInit[npcId] = true
            self.LikeBtnGroupList[npcId]:SelectIndex(self.LikeStatus[npcId])
        else
            self:ChangeLikeCount(npcId)
        end

        if EvaluateOneForAll == XArchiveConfigs.OnForAllState.On then
            break
        end
    end
    self.BtnGroup.gameObject:SetActiveEx(false)
end

function XUiArchiveMonsterSynopsis:SelectLikeOrDis(npcId, index)
    if not self.IsLikeInit[npcId] then
        if index == self.LikeStatus[npcId] then
            self.LikeStatus[npcId] = XArchiveConfigs.EquipLikeType.NULL
        else
            self.LikeStatus[npcId] = index
        end
        XUiManager.TipText("ArchiveMonsterEvaluateHint")
    end

    self.IsLikeInit[npcId] = false
    self:ChangeLikeCount(npcId)

end

function XUiArchiveMonsterSynopsis:ChangeLikeCount(npcId)
    if self.LikeStatus[npcId] == XArchiveConfigs.EquipLikeType.Dis then
        self.MyDisCount = 1
        self.MyLikeCount = 0
    elseif self.LikeStatus[npcId] == XArchiveConfigs.EquipLikeType.Like then
        self.MyDisCount = 0
        self.MyLikeCount = 1
    else
        self.MyDisCount = 0
        self.MyLikeCount = 0
    end

    if self.OldLikeStatus[npcId] == XArchiveConfigs.EquipLikeType.Dis then
        self.MyDisCount = self.MyDisCount - 1
    elseif self.OldLikeStatus[npcId] == XArchiveConfigs.EquipLikeType.Like then
        self.MyLikeCount = self.MyLikeCount - 1
    end

    self.LikeBtnObjList[npcId].BtnStep:SetName(CSTextManagerGetText("ChannelNumberLabel",
            XArchiveConfigs.GetCountUnitChange(self.DisCount[npcId] + self.MyDisCount)))

    self.LikeBtnObjList[npcId].BtnLike:SetName(CSTextManagerGetText("ChannelNumberLabel",
            XArchiveConfigs.GetCountUnitChange(self.LikeCount[npcId] + self.MyLikeCount)))
end

function XUiArchiveMonsterSynopsis:SelectType(index)
    self:SetMonsterInfoData(index)
    self:SetMonsterSettingData(index)
    self:SetMonsterFeaturesData()
    self:SetPlayerEvaluateData(index)
end

function XUiArchiveMonsterSynopsis:SetMonsterInfoData(type)
    local infoList = XDataCenter.ArchiveManager.GetArchiveMonsterInfoList(self.Data:GetNpcId(type), XArchiveConfigs.MonsterInfoType.Short)

    self.MonsterInfo.LockedGroup.gameObject:SetActiveEx(self.Data:GetIsLockMain())
    self.MonsterInfo.UnLock.gameObject:SetActiveEx(not self.Data:GetIsLockMain())
    self.MonsterInfo.MonsterNameTex.text = self.Data:GetIsLockMain() and LockNameText or
    ((EvaluateOneForAll == XArchiveConfigs.OnForAllState.On) and self.Data:GetName() or self.Data:GetRealName(self.Data:GetNpcId(type)))

    if self.Data:GetIsLockMain() then
        return
    end
    self.MonsterInfo.KillCount.text = CSTextManagerGetText("ArchiveMonsterKillText", self.Data:GetKill(self.Data:GetNpcId(type)))

    for index = 1, InfoMax do
        if infoList[index] then
            if not self.Info then self.Info = {} end

            if not self.Info[index] then
                self.Info[index] = {}
                self.Info[index].Transform = self.MonsterInfo.InfoContent[index].transform
                self.Info[index].GameObject = self.MonsterInfo.InfoContent[index].gameObject
                XTool.InitUiObject(self.Info[index])
            end
            self.Info[index].TxtTitle.text = infoList[index]:GetTitle()
            self.Info[index].TxtDesc.text = infoList[index]:GetText()
            self.Info[index].TxtLock.text = infoList[index]:GetLockDesc()
            self.Info[index].UnLock.gameObject:SetActiveEx(not infoList[index]:GetIsLock())
            self.Info[index].Lock.gameObject:SetActiveEx(infoList[index]:GetIsLock())
        end
        self.MonsterInfo.InfoContent[index].gameObject:SetActiveEx(infoList[index] and true or false)
    end

    self.CurInfoData.Name = self.MonsterInfo.MonsterNameTex.text
    self.CurInfoData.Icon = self.Data:GetIcon()
    self.CurInfoData.Img = self.Data:GetPic()
end

function XUiArchiveMonsterSynopsis:SetMonsterSettingData(type)
    local skillList = XDataCenter.ArchiveManager.GetArchiveMonsterSkillList(self.Data:GetNpcId(type))
    self.MonsterSetting.UnLock.gameObject:SetActiveEx(not self.Data:GetIsLockMain())
    self.MonsterSetting.BtnSkill.gameObject:SetActiveEx(#skillList > 0)
end

function XUiArchiveMonsterSynopsis:SetMonsterFeaturesData()
    local featuresIds = self.Data:GetTagIds()
    self.MonsterFeatures.LockedGroup.gameObject:SetActiveEx(self.Data:GetIsLockMain())
    self.MonsterFeatures.UnLock.gameObject:SetActiveEx(not self.Data:GetIsLockMain())

    if self.Data:GetIsLockMain() then
        return
    end

    for index = 1, TagMax do
        if featuresIds[index] then
            if not self.MonsterFeatures.TagItem then self.MonsterFeatures.TagItem = {} end

            if not self.MonsterFeatures.TagItem[index] then
                self.MonsterFeatures.TagItem[index] = {}
                self.MonsterFeatures.TagItem[index].Transform = self.MonsterFeatures.TagItemObj[index].transform
                self.MonsterFeatures.TagItem[index].GameObject = self.MonsterFeatures.TagItemObj[index].gameObject
                XTool.InitUiObject(self.MonsterFeatures.TagItem[index])
            end
            self.MonsterFeatures.TagItem[index].TxtTag.text = XArchiveConfigs.GetArchiveTagCfgById(featuresIds[index]).Name
            local hexColor = XArchiveConfigs.GetArchiveTagCfgById(featuresIds[index]).Color
            self.MonsterFeatures.TagItem[index].TxtTag.color = XUiHelper.Hexcolor2Color(hexColor)
            local bgImg = XArchiveConfigs.GetArchiveTagCfgById(featuresIds[index]).Bg
            if bgImg then self.Base:SetUiSprite(self.MonsterFeatures.TagItem[index].Bg, bgImg) end
        end
        self.MonsterFeatures.TagItemObj[index].gameObject:SetActiveEx(featuresIds[index] and true or false)
    end
end

function XUiArchiveMonsterSynopsis:SetPlayerEvaluateData(type)
    local NpcType
    local evaluate
    local mySelfEvaluateList
    self.PlayerEvaluate.LockedGroup.gameObject:SetActiveEx(self.Data:GetIsLockMain())
    self.PlayerEvaluate.UnLock.gameObject:SetActiveEx(not self.Data:GetIsLockMain())
    self.RightBottom.gameObject:SetActiveEx(not self.Data:GetIsLockMain())
    if self.Data:GetIsLockMain() then
        return
    end

    NpcType = (EvaluateOneForAll == XArchiveConfigs.OnForAllState.On) and 1 or type
    evaluate = self.EvaluateList[self.Data:GetNpcId(NpcType)]

    if evaluate then
        local score = math.floor(evaluate.Score / (evaluate.ScoreCount ~= 0 and evaluate.ScoreCount or 1))
        evaluate.AverageScore = evaluate.Score and score or 0

        local difficulty = math.floor(evaluate.Difficulty / (evaluate.DifficultyCount ~= 0 and evaluate.DifficultyCount or 1))
        evaluate.AverageDifficulty = evaluate.Difficulty and difficulty or 0
    end

    mySelfEvaluateList = self.MySelfEvaluateList[self.Data:GetNpcId(NpcType)]
    self:SelectLikeBtnGroup(self.Data:GetNpcId(NpcType))
    --------------------------------------------------------------------------------评价
    for index = 1, TagMax do
        if evaluate and evaluate.Tags and evaluate.Tags[index] then
            if not self.PlayerEvaluate.TagItem then self.PlayerEvaluate.TagItem = {} end

            if not self.PlayerEvaluate.TagItem[index] then
                self.PlayerEvaluate.TagItem[index] = {}
                self.PlayerEvaluate.TagItem[index].Transform = self.PlayerEvaluate.TagItemObj[index].transform
                self.PlayerEvaluate.TagItem[index].GameObject = self.PlayerEvaluate.TagItemObj[index].gameObject
                XTool.InitUiObject(self.PlayerEvaluate.TagItem[index])
            end
            self.PlayerEvaluate.TagItem[index].TxtTag.text = XArchiveConfigs.GetArchiveTagCfgById(evaluate.Tags[index].Id).Name
            local hexColor = XArchiveConfigs.GetArchiveTagCfgById(evaluate.Tags[index].Id).Color
            self.PlayerEvaluate.TagItem[index].TxtTag.color = XUiHelper.Hexcolor2Color(hexColor)
            local bgImg = XArchiveConfigs.GetArchiveTagCfgById(evaluate.Tags[index].Id).Bg
            if bgImg then self.Base:SetUiSprite(self.PlayerEvaluate.TagItem[index].Bg, bgImg) end
        end
        self.PlayerEvaluate.TagItemObj[index].gameObject:SetActiveEx((evaluate and evaluate.Tags and evaluate.Tags[index]) and true or false)
    end
    --------------------------------------------------------------------------------评分
    for index = 1, ScoreMax do
        self.PlayerEvaluate.GradeIcon[index].gameObject:SetActiveEx(evaluate and evaluate.AverageScore and index <= evaluate.AverageScore)
    end

    for index = 1, DifficultyMax do
        self.PlayerEvaluate.LevelIcon[index].gameObject:SetActiveEx(evaluate and evaluate.AverageDifficulty and index <= evaluate.AverageDifficulty)
    end
    --------------------------------------------------------------------------------记录
    self.CurEvaluateData = evaluate
    self.CurMySelfEvaluateData = mySelfEvaluateList
    self.CurType = NpcType
end

function XUiArchiveMonsterSynopsis:SelectLikeBtnGroup(npcId)
    for id, likeBtnGroup in pairs(self.LikeBtnGroupList or {}) do
        likeBtnGroup.gameObject:SetActiveEx(npcId == id)
    end
end

function XUiArchiveMonsterSynopsis:GiveLikeStatus()
    local changedLikeList = {}
    for k, _ in pairs(self.LikeStatus or {}) do
        if self.LikeStatus[k] ~= self.OldLikeStatus[k] then
            local tmp = {}
            tmp.Id = k
            tmp.LikeStatus = self.LikeStatus[k]
            tableInsert(changedLikeList, tmp)
        end
    end
    if #changedLikeList > 0 then
        XDataCenter.ArchiveManager.MonsterGiveLike(changedLikeList)
    end
end


function XUiArchiveMonsterSynopsis:OnBtnPlayerEvaluateClick()
    self.Base:OpenOneChildUi(childUiComment, self)
end

function XUiArchiveMonsterSynopsis:OnBtnEvaluateClick()
    self.Base:OpenOneChildUi(childUiEvaluate, self, function()
            self:SelectType(self.CurType)
        end)
end

function XUiArchiveMonsterSynopsis:OnMonsterInfoBtnClick()
    self.Base:SelectDetailState(XArchiveConfigs.MonsterDetailType.Info)
    XDataCenter.ArchiveManager.ClearDetailRedPoint(XArchiveConfigs.MonsterDetailType.Info, { self.Data })
end

function XUiArchiveMonsterSynopsis:OnMonsterSetBtnClick()
    self.Base:SelectDetailState(XArchiveConfigs.MonsterDetailType.Setting)
    XDataCenter.ArchiveManager.ClearDetailRedPoint(XArchiveConfigs.MonsterDetailType.Setting, { self.Data })
end

function XUiArchiveMonsterSynopsis:OnMonsterSkillStateBtnClick()
    self.Base:SelectDetailState(XArchiveConfigs.MonsterDetailType.Skill)
    XDataCenter.ArchiveManager.ClearDetailRedPoint(XArchiveConfigs.MonsterDetailType.Skill, { self.Data })
end

function XUiArchiveMonsterSynopsis:OnCheckInfoRedDot(count)
    self.MonsterInfo.BtnMore:ShowReddot(count >= 0)
end

function XUiArchiveMonsterSynopsis:OnCheckSkillRedDot(count)
    self.MonsterSetting.BtnSkill:ShowReddot(count >= 0)
end

function XUiArchiveMonsterSynopsis:OnCheckSettingRedDot(count)
    self.MonsterSetting.BtnSet:ShowReddot(count >= 0)
end