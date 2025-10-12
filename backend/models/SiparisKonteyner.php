<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "siparis_konteyner".
 *
 * @property int $id
 * @property int|null $siparis_id satin_alma_siparis_fis tablosuna referans
 * @property int|null $container_id containers tablosuna referans
 * @property string|null $created_at
 * @property string|null $updated_at
 */
class SiparisKonteyner extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'siparis_konteyner';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['siparis_id', 'container_id', 'custom_qty'], 'default', 'value' => null],
            [['siparis_id', 'container_id', 'custom_qty'], 'integer'],
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
            'siparis_id' => 'Siparis ID',
            'container_id' => 'Container ID',
            'custom_qty' => 'Custom Pallet Qty',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
        ];
    }

}
