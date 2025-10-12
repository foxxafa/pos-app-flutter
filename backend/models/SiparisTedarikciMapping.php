<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "siparis_tedarikci_mapping".
 *
 * @property int $id
 * @property int|null $siparis_id
 * @property int|null $tedarikci_id
 *
 * @property SatinAlmaSiparisFis $siparis
 * @property Tedarikci $tedarikci
 */
class SiparisTedarikciMapping extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'siparis_tedarikci_mapping';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['siparis_id', 'tedarikci_id'], 'default', 'value' => null],
            [['siparis_id', 'tedarikci_id'], 'integer'],
            [['siparis_id'], 'exist', 'skipOnError' => true, 'targetClass' => SatinAlmaSiparisFis::class, 'targetAttribute' => ['siparis_id' => 'id']],
            [['tedarikci_id'], 'exist', 'skipOnError' => true, 'targetClass' => Tedarikci::class, 'targetAttribute' => ['tedarikci_id' => 'id']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'siparis_id' => 'Order ID',
            'tedarikci_id' => 'Supplier ID',
        ];
    }

    /**
     * Gets query for [[Siparis]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getSiparis()
    {
        return $this->hasOne(SatinAlmaSiparisFis::class, ['id' => 'siparis_id']);
    }

    /**
     * Gets query for [[Tedarikci]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getTedarikci()
    {
        return $this->hasOne(Tedarikci::class, ['id' => 'tedarikci_id']);
    }

}
