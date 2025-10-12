<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\Satiscilar;

/**
 * SatiscilarSearch represents the model behind the search form of `app\models\Satiscilar`.
 */
class SatiscilarSearch extends Satiscilar
{
    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['__format', '_cdate', '_date', 'aciklama', 'carikodu', 'cariunvan', 'ceptel', 'durum', 'ekleyenkullaniciadi', 'eposta', 'isyerikredikartlari', 'kodu', 'kullaniciadi', 'ozelkodu', 'pozisyon'], 'safe'],
            [['_key', '_key_scf_carikart', '_key_scf_pozisyon', '_key_sis_depo', '_key_sis_ozelkod', '_key_sis_seviyekodu', '_key_sis_sube', '_level1', '_level2', '_owner', '_serial', '_user'], 'integer'],
            [['maxindirimorani'], 'number'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function scenarios()
    {
        // bypass scenarios() implementation in the parent class
        return Model::scenarios();
    }

    /**
     * Creates data provider instance with search query applied
     *
     * @param array $params
     * @param string|null $formName Form name to be used into `->load()` method.
     *
     * @return ActiveDataProvider
     */
    public function search($params, $formName = null)
    {
        $query = Satiscilar::find();

        // add conditions that should always apply here

        $dataProvider = new ActiveDataProvider([
            'query' => $query,
        ]);

        $this->load($params, $formName);

        if (!$this->validate()) {
            // uncomment the following line if you do not want to return any records when validation fails
            // $query->where('0=1');
            return $dataProvider;
        }

        // grid filtering conditions
        $query->andFilterWhere([
            '_cdate' => $this->_cdate,
            '_date' => $this->_date,
            '_key' => $this->_key,
            '_key_scf_carikart' => $this->_key_scf_carikart,
            '_key_scf_pozisyon' => $this->_key_scf_pozisyon,
            '_key_sis_depo' => $this->_key_sis_depo,
            '_key_sis_ozelkod' => $this->_key_sis_ozelkod,
            '_key_sis_seviyekodu' => $this->_key_sis_seviyekodu,
            '_key_sis_sube' => $this->_key_sis_sube,
            '_level1' => $this->_level1,
            '_level2' => $this->_level2,
            '_owner' => $this->_owner,
            '_serial' => $this->_serial,
            '_user' => $this->_user,
            'maxindirimorani' => $this->maxindirimorani,
        ]);

        $query->andFilterWhere(['like', '__format', $this->__format])
            ->andFilterWhere(['like', 'aciklama', $this->aciklama])
            ->andFilterWhere(['like', 'carikodu', $this->carikodu])
            ->andFilterWhere(['like', 'cariunvan', $this->cariunvan])
            ->andFilterWhere(['like', 'ceptel', $this->ceptel])
            ->andFilterWhere(['like', 'durum', $this->durum])
            ->andFilterWhere(['like', 'ekleyenkullaniciadi', $this->ekleyenkullaniciadi])
            ->andFilterWhere(['like', 'eposta', $this->eposta])
            ->andFilterWhere(['like', 'isyerikredikartlari', $this->isyerikredikartlari])
            ->andFilterWhere(['like', 'kodu', $this->kodu])
            ->andFilterWhere(['like', 'kullaniciadi', $this->kullaniciadi])
            ->andFilterWhere(['like', 'ozelkodu', $this->ozelkodu])
            ->andFilterWhere(['like', 'pozisyon', $this->pozisyon]);

        return $dataProvider;
    }
}
