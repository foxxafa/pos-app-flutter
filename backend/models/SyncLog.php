<?php
namespace app\models;

use Yii;
use yii\db\ActiveRecord;
use yii\behaviors\TimestampBehavior;

class SyncLog extends ActiveRecord
{
    public static function tableName()
    {
        return '{{%sync_log}}';
    }

    public function rules()
    {
        return [
            [['varlik_adi'], 'required'],
            [['son_tarih', 'update_date'], 'safe'],
            [['varlik_adi'], 'string', 'max' => 100],
            [['aciklama'], 'string'],
            [['varlik_adi'], 'unique'],
        ];
    }

    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'varlik_adi' => 'Varlık Adı', //fatura, faturakalem, stok, stokhareket
            'son_tarih' => 'Son Tarih',
            'update_date' => 'Güncelleme Tarihi',
            'aciklama' => 'Açıklama',
        ];
    }

    public function behaviors()
    {
        return [
            [
                'class' => TimestampBehavior::class,
                'createdAtAttribute' => null,
                'updatedAtAttribute' => 'update_date',
                'value' => function () {
                    return date('Y-m-d H:i:s');
                },
            ],
        ];
    }
}


