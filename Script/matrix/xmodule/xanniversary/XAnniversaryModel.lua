---@class XAnniversaryModel : XModel
local XAnniversaryModel = XClass(XModel, "XAnniversaryModel")

local TableKeyMap={
    AnniversaryActivity={DirPath=XConfigUtil.DirectoryType.Share,Identifier='ID'},
    AnniversaryReviewPictures={DirPath=XConfigUtil.DirectoryType.Client,Identifier='Id'},
    AnniversaryReviewDataUI={DirPath=XConfigUtil.DirectoryType.Client,Identifier='Id',ReadFunc=XConfigUtil.ReadType.String},
    AnniversaryReivewSharePlatforms={DirPath=XConfigUtil.DirectoryType.Client},
    AnniversaryReviewTopics={DirPath=XConfigUtil.DirectoryType.Client,Identifier='Id',ReadFunc=XConfigUtil.ReadType.String},
}

function XAnniversaryModel:OnInit()
    --初始化内部变量
    self._ConfigUtil:InitConfigByTableKey('MiniActivity/AnniversaryActivity',TableKeyMap,XConfigUtil.CacheType.Private)

end

function XAnniversaryModel:ClearPrivate()
    --这里执行内部数据清理
end

function XAnniversaryModel:ResetAll()
    --这里执行重登数据清理
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

----------config start----------

function XAnniversaryModel:GetAnniversaryActivity()
    return self._ConfigUtil:GetByTableKey(TableKeyMap.AnniversaryActivity)
end

function XAnniversaryModel:GetAnniversaryReviewPictures()
    return self._ConfigUtil:GetByTableKey(TableKeyMap.AnniversaryReviewPictures)
end

function XAnniversaryModel:GetAnniversaryReviewDataUI()
    return self._ConfigUtil:GetByTableKey(TableKeyMap.AnniversaryReviewDataUI)
end

function XAnniversaryModel:GetAnniversaryReivewSharePlatforms()
    return self._ConfigUtil:GetByTableKey(TableKeyMap.AnniversaryReivewSharePlatforms)
end

function XAnniversaryModel:GetAnniversaryReviewTopics()
    return self._ConfigUtil:GetByTableKey(TableKeyMap.AnniversaryReviewTopics)
end

----------config end----------


return XAnniversaryModel