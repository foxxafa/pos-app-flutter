<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "siparis_konteyner_icerik".
 *
 * @property int $id
 * @property int|null $siparis_konteyner_id siparis_konteyner tablosuna referans
 * @property int|null $siparis_satir_id satin_alma_siparis_fis_satir tablosuna referans
 * @property int|null $palet_sayisi
 * @property string|null $created_at
 * @property string|null $updated_at
 */
class SiparisKonteynerIcerik extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'siparis_konteyner_icerik';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['siparis_konteyner_id', 'siparis_satir_id', 'palet_sayisi'], 'default', 'value' => null],
            [['siparis_konteyner_id', 'siparis_satir_id', 'palet_sayisi'], 'integer'],
            [['created_at', 'updated_at'], 'safe'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'siparis_konteyner_id' => 'Siparis Konteyner ID',
            'siparis_satir_id' => 'Siparis Satir ID',
            'palet_sayisi' => 'Palet Sayisi',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
        ];
    }

}
