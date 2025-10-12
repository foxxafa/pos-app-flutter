<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "barkodlar".
 *
 * @property int $id
 * @property string|null $_key
 * @property string|null $_key_scf_stokkart_birimleri
 * @property string|null $barkod
 * @property string|null $turu
 *
 * @property Birimler $birim
 */
class Barkodlar extends \yii\db\ActiveRecord
{
    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'barkodlar';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['_key', '_key_scf_stokkart_birimleri', 'barkod', 'turu'], 'default', 'value' => null],
            [['_key', '_key_scf_stokkart_birimleri'], 'string', 'max' => 45],
            [['barkod'], 'string', 'max' => 255],
            [['turu'], 'string', 'max' => 5],
            [['_key'], 'unique'],
            [['_key_scf_stokkart_birimleri'], 'exist', 'skipOnError' => true, 'targetClass' => Birimler::class, 'targetAttribute' => ['_key_scf_stokkart_birimleri' => '_key']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            '_key' => 'Key',
            '_key_scf_stokkart_birimleri' => 'Key Scf Stokkart Birimleri',
            'barkod' => 'Barkod',
            'turu' => 'Turu',
        ];
    }

    /**
     * Gets query for [[Birim]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getBirim()
    {
        return $this->hasOne(Birimler::class, ['_key' => '_key_scf_stokkart_birimleri']);
    }
} 