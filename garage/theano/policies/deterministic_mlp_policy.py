import lasagne.init as LI
import lasagne.layers as L
import lasagne.nonlinearities as NL

from garage.core import Serializable
from garage.policies import Policy
from garage.theano.core import batch_norm
from garage.theano.core import LasagnePowered
from garage.theano.misc import tensor_utils
from garage.theano.spaces import Box


class DeterministicMLPPolicy(Policy, LasagnePowered):
    def __init__(self,
                 env_spec,
                 hidden_sizes=(32, 32),
                 hidden_nonlinearity=NL.rectify,
                 hidden_w_init=LI.HeUniform(),
                 hidden_b_init=LI.Constant(0.),
                 output_nonlinearity=NL.tanh,
                 output_w_init=LI.Uniform(-3e-3, 3e-3),
                 output_b_init=LI.Uniform(-3e-3, 3e-3),
                 bn=False):

        assert isinstance(env_spec.action_space, Box)

        Serializable.quick_init(self, locals())

        l_obs = L.InputLayer(shape=(None, env_spec.observation_space.flat_dim))

        l_hidden = l_obs
        if bn:
            l_hidden = batch_norm(l_hidden)

        for idx, size in enumerate(hidden_sizes):
            l_hidden = L.DenseLayer(
                l_hidden,
                num_units=size,
                W=hidden_w_init,
                b=hidden_b_init,
                nonlinearity=hidden_nonlinearity,
                name="h%d" % idx)
            if bn:
                l_hidden = batch_norm(l_hidden)

        l_output = L.DenseLayer(
            l_hidden,
            num_units=env_spec.action_space.flat_dim,
            W=output_w_init,
            b=output_b_init,
            nonlinearity=output_nonlinearity,
            name="output")

        # Note the deterministic=True argument. It makes sure that when getting
        # actions from single observations, we do not update params in the
        # batch normalization layers

        action_var = L.get_output(l_output, deterministic=True)
        self._output_layer = l_output

        self._f_actions = tensor_utils.compile_function([l_obs.input_var],
                                                        action_var)

        super(DeterministicMLPPolicy, self).__init__(env_spec)
        LasagnePowered.__init__(self, [l_output])

    def get_action(self, observation):
        action = self._f_actions([observation])[0]
        return action, dict()

    def get_actions(self, observations):
        return self._f_actions(observations), dict()

    def get_action_sym(self, obs_var):
        return L.get_output(self._output_layer, obs_var)
